module Zena
  module Acts
    module Enrollable
      module Named
        def self.included(base)
          class << base
            # Pseudo class name
            attr_accessor :to_s, :klass
          end
        end
      end

      # FIXME: remove all this and simply use VirtualClass['NNP'] in RubyLess:
      #        write 'safe_method_type' for VirtualClass and forward from there to the real_class
      # def self.make_class(klass)
      #   if klass.kind_of?(VirtualClass)
      #     res_class = Class.new(klass.real_class) do
      #       include Named
      #     end
      #   elsif klass <= Node
      #     res_class = Class.new(klass) do
      #       include Named
      #     end
      #   else
      #     return klass
      #   end
      #
      #
      #   res_class.to_s  = klass.name
      #   res_class.kpath = klass.kpath
      #   res_class.klass = klass
      #
      #   res_class.load_roles!
      #   res_class
      # end

      module LoadRoles
        # FIXME: can we remove or move the 'enroll' stuff to VirtualClass ?
        def safe_method_type(signature, receiver = nil)
          if type = super
            if type[:enroll]
              klass = type[:class]
              if klass.kind_of?(Array)
                if klass = Enrollable::Common.get_class(klass.first.to_s)
                  klass = [klass]
                else
                  return nil
                end
              elsif klass
                unless klass = Enrollable::Common.get_class(klass.to_s)
                  return nil
                end
              else
                return nil
              end
              type.merge(:class => klass)
            else
              type
            end
          end
        end
      end # LoadRoles

      module ModelMethods
        def self.included(base)
          base.extend LoadRoles

          class << base
            attr_accessor :loaded_role_properties
            attr_accessor :declared_node_contexts, :declared_node_contexts_proc

            def loaded_role_properties
              @loaded_role_properties ||= {}
            end

            # Declare a safe context resulting in a (virtual) sub-class of Node. This method
            # ensures that the returned class will load the Roles available. If you need to
            # use a virtual-class, you must declare it by using a Symbol or RubyLess will try
            # to resolve it as a real class resulting in a NameError.
            def safe_node_context(methods_hash)
              methods_hash[:defaults] ||= {}
              methods_hash[:defaults][:nil]    = true
              methods_hash[:defaults][:enroll] = true
              safe_method(methods_hash)
            end
          end

          base.class_eval do
            attr_accessor :loaded_role_properties
            include LoadRoles

            def loaded_role_properties
              @loaded_role_properties ||= {}
            end

            before_validation  :prepare_roles
            after_save  :update_roles
            after_destroy :destroy_nodes_roles
            has_and_belongs_to_many :roles, :class_name => '::Role'
            safe_context :roles  => {:class => [Role], :method => 'assigned_roles'}

            property do |p|
              p.serialize :cached_role_ids, Array
            end
          end
        end

        def has_role?(role_id)
          if role_id.kind_of?(Fixnum)
            (cached_role_ids || []).include?(role_id)
          else
            super
          end
        end

        def zafu_possible_roles
          # Only select database stored roles
          roles = virtual_class.sorted_roles.select {|r| r.id && r.class == Role }
          roles.empty? ? nil : roles
        end

        def assigned_roles
          return nil unless role_ids = self.prop['cached_role_ids']
          roles = (schema.sorted_roles || []).select do |role|
            role_ids.include?(role.id)
          end
          roles.empty? ? nil : roles
        end

        private

          # Do not go any further if the object contains errors
          # def check_unknown_attributes
          #   if @unknown_attribute_error
          #     name = @unknown_attribute_error.message[%r{unknown attribute: (.+)}, 1]
          #     errors.add(name, "unknown attribute")
          #     @unknown_attribute_error = nil
          #     false
          #   else
          #     true
          #   end
          # end

          # Prepare roles to add/remove to object.
          def prepare_roles
            return unless prop.changed?

            keys = []
            properties.each do |k, v|
              keys << k unless v.blank?
            end

            role_ids = []
            virtual_class.sorted_roles.each do |role|
              # Do not index VirtualClasses (information exists through kpath) and do not
              # index static roles.
              next unless role.class == Role && role.id
              role_ids << role.id if role.column_names & keys != []
            end

            prop['cached_role_ids'] = role_ids
          end

          def update_roles
            return if version.status < Zena::Status[:pub]

            # High status, rebuild role index

            if cached_role_ids.blank?
              Zena::Db.execute("DELETE FROM nodes_roles WHERE node_id = #{Zena::Db.quote(self.id)}")
            else
              current_ids = Zena::Db.fetch_ids("SELECT role_id FROM nodes_roles WHERE node_id = #{Zena::Db.quote(self.id)}", 'role_id')
              add_roles = cached_role_ids - current_ids
              del_roles = current_ids - cached_role_ids

              if !add_roles.blank?
                Zena::Db.insert_many('nodes_roles', %W{node_id role_id}, add_roles.map {|role_id| [self.id, role_id]})
              end

              if !del_roles.blank?
                Zena::Db.execute("DELETE FROM nodes_roles WHERE node_id = #{Zena::Db.quote(self.id)} AND role_id IN (#{del_roles.map{|r| Zena::Db.quote(r)}.join(',')})")
              end
            end
          end

          def destroy_nodes_roles
            Zena::Db.execute("DELETE FROM nodes_roles WHERE node_id = #{Zena::Db.quote(self.id)}")
          end

      end # ModelMethods

      module Common
        extend self
        def get_class(class_name)
          VirtualClass.find_by_name(class_name)
        end
      end # Common

      module ZafuMethods
        include Common

        # This is used to resolve 'this' (current NodeContext), '@node' as NodeContext with class Node,
        # '@page' as first NodeContext of type Page, @letter, etc.
        # We overwrite Zafu's version to cope with our anonymous classes.
        def node_context_from_signature(signature)
          return nil unless signature.size == 1
          ivar = signature.first
          if ivar == 'this'
            super
          elsif ivar[0..0] == '@' && klass = get_class(ivar[1..-1].capitalize)

            if klass <= Node
              # We have to get 'up' class with a little more skill because of enrollable's anonymous classes.
              kpath = klass.kpath
              node = self.node
              while node &&
                    (node.list_context? || !(node.klass <= Node) || !(node.klass.kpath =~ /^#{kpath}/))
                node = node.up
              end
            else
              node = self.node(klass)
            end

            if node
              {:class => node.klass, :method => node.name}
            else
              nil
            end
          else
            nil
          end
        end

      end

      module ControllerMethods
        include Common
      end # ControllerMethods

      module ViewMethods
        include Common
      end # ViewMethods
    end # Enrollable
  end # Acts
end # Zena