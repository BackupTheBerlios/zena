require 'query_builder'

# Since QueryNode uses a special scope (secure_scope) that needs to be evaluated _in the query string_, you cannot
# use query.sql. You have to use: eval query.to_s. This is not an issue since normal useage for QueryNode is to be
# compilated into an ERB template.
module Zena
  module Use
    module QueryNode

      module ModelMethods
        def self.included(base)
          base.send(:include, QueryBuilder)
          base.extend ClassMethods
          base.query_compiler = Zena::Use::QueryNode::Compiler
        end

        # Find a node and propagate visitor
        def do_find(count, query, ignore_source = false, klass = Node)
          return nil if query.empty?
          return nil if (new_record? && !ignore_source) # do not run query (might contain nil id)

          case count
          when :all
            res = klass.find_by_sql(query)
            secure_result(Node, res) if res
          when :first
            res = klass.find_by_sql(query).first
            secure_result(Node, res) if res
          when :count
            klass.count_by_sql(query)
          else
            nil
          end
        end

        # Find related nodes.
        # See Node#build_find for details on the options available.
        # TODO: replace with rubyless translate ? Is this thing really used anyway ?
        def find(count, rel, opts = {})
          rel = [rel] if rel.kind_of?(String)

          if !opts[:skip_rubyless] && rel.size == 1 && type = RubyLess::SafeClass.safe_method_type_for(self.class, [rel.first])
            self.send(type[:method])
          else
            query = self.class.build_find(count, rel, :node_name => 'self')
            if query.valid?
              do_find(count, eval(query.to_s))
            else
              nil
            end
          end
        end
      end # ModelMethods

      module ClassMethods
        # Return the name of the group used for custom queries
        def query_group
          visitor.site.host
        end
      end

      class Compiler < QueryBuilder::Processor
        attr_reader :context # ?
        set_main_table 'nodes'
        set_main_class 'Node'
        set_default :scope,   'self'
        set_default :order,   'position ASC, name ASC'
        set_default :context, 'self'
        after_process :secure_query

        load_custom_queries ["#{RAILS_ROOT}/bricks/*/queries"]

        CORE_CONTEXTS = %w{parent project section}

        class << self
          attr_accessor :filter_fields

          def add_filter_field(key, fld_def)
            self.filter_fields[key] = fld_def
          end
        end

        self.filter_fields = {'id' => {:key => 'zip'}}

        # Scope current context with previous context.
        # For example:
        #                          current         previous
        #  ['parent_id', 'id'] ==> no1.parent_id = nodes.id
        def scope_fields(scope)
          deb 'scope_fields', scope
          case scope
          when 'self'
            ['parent_id', 'id']
          when 'parent'
            last? ? ['parent_id', 'parent_id'] : ['parent_id', 'id']
          when 'project'
            last? ? ['project_id', 'project_id'] : ['project_id', 'id']
          when 'site'
            # not an error, but do not scope
            []
          else
            # error
            nil
          end
        end

        def process_attr(fld_name)
          if fld_name == 'id'
            # Special case because 'id' is rewritten as 'zip' by RubyLess in Node
            super.sub('zip', 'id')
          else
            super
          end
        end

        # Overwrite this and take car to check for valid fields.
        def process_field(fld_name)
          if map_def = self.class.filter_fields[fld_name]
            if table_def = map_def[:table]
              table_to_use = needs_join_table(*table_def)
            else
              table_to_use = main_table
            end
            "#{table_to_use}.#{map_def[:key]}"
          elsif %w{id parent_id project_id section_id}.include?(fld_name) ||
            (Node.safe_method_type([fld_name]) && Node.column_names.include?(fld_name))
            "#{table}.#{fld_name}"
          else
          #elsif fld_name == 'REF_DATE'
          #  context[:ref_date] ? insert_bind(context[:ref_date]) : 'now()'
          #else
            super # raises an error
          end
        end

        def process_equal(left, right)
          if left == [:field, 'class'] && right[0] == :string
            case right.last
            when 'Client'
              kpath = 'NRCC'
            else
              raise QueryBuilder::QueryException.new("Unknown class #{right.last.inspect}.")
            end
            "#{field_or_attr('kpath')} LIKE #{insert_bind((kpath + '%').inspect)}"
          else
            super
          end
        end


        # ******** And maybe overwrite these **********
        def parse_custom_query_argument(key, value)
          return nil unless value
          super(key, value.gsub('REF_DATE', context[:ref_date] ? insert_bind(context[:ref_date]) : 'now()'))
        end

        private
          # Change class
          def class_relation(relation)
            case relation
            when 'users'
              change_processor 'UserProcessor'
              add_table('users')
              add_filter "#{table('users')}.node_id = #{field_or_attr('id', table(self.class.main_table))}"
              return true
            else
              return nil
            end
          end

          # Moving to another context without a join table
          def context_relation(relation)
            # Not sure we need all these anymore...
            #case relation
            #when 'self'
            #  # Dummy context
            #  fields = ['id', 'id']
            #when 'parent', 'project', 'section'
            #  # Core contexts
            #  fields = ['id', "#{relation}_id"]
            #when 'parents', 'projects', 'sections'
            #  if @table_counter[main_table] > 0 || @tables.include?('links')
            #    fields = ['id', "#{relation[0..-2]}_id"]
            #  end
            #when 'root'
            #  # Special pseudo-context
            #  @where << "#{table}.id = #{current_site.root_id}"
            #  return true
            #when 'author', 'traductions', 'versions'
            #  # TODO: not implemented yet...
            #  return nil
            #when 'visitor'
            #  # Special pseudo-context
            #  @where << "#{table}.id = #{insert_bind("visitor.contact_id")}"
            #  return true
            #end

            if CORE_CONTEXTS.include?(relation)
              # PREVIOUS_GROUP.id = NEW_GROUP.project_id
              add_table(main_table)
              add_filter "#{field_or_attr('id')} = #{field_or_attr("#{relation}_id", table(main_table, -1))}"
            elsif relation == main_table
              nil
            else
              # Not a core context, try to filter by class type
              if klass = Node.get_class(relation)
                add_table(main_table)
                add_filter "#{field_or_attr('kpath')} LIKE '#{klass.kpath}%'"
              else
                # unknown class
                nil
              end
            end
          end

          # Filtering of objects in scope
          def filter_relation(relation)
            case relation
            when 'letters'
              add_table(main_table)
              add_filter "#{table}.kpath LIKE #{insert_bind("NNL%".inspect)}"
            when 'clients'
              add_table(main_table)
              add_filter "#{table}.kpath LIKE #{insert_bind("NRCC%".inspect)}"
            when main_table, 'children'
              # no filter
              add_table(main_table)
            end
          end

          # Moving to another context through 'joins'
          def join_relation(relation)
            if rel = RelationProxy.find_by_role(relation.singularize)
              add_table(main_table)
              add_table('links')

              # source --> target
              add_filter "#{field_or_attr('id')} = #{table('links')}.#{rel.other_side} AND #{table('links')}.relation_id = #{rel.id} AND #{table('links')}.#{rel.link_side} = #{field_or_attr('id', table(main_table,-1))}"
            else
              nil
            end
          end

          def secure_query
            query.add_filter "\#{secure_scope('#{table}')}"
          end
      end # Compiler
    end # QueryNode
  end # Use
end # Zena

