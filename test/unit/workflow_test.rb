# encoding: utf-8
require 'test_helper'

class WorkflowTest < Zena::Unit::TestCase

  def defaults
    { :title     => 'hello',
      :parent_id => nodes_id(:zena) }
  end

  # =========== FIND VERSION TESTS =============

  context 'A visitor without write access' do
    setup do
      login(:anon)
    end

    should 'see a publication in her language' do
      node = secure!(Node) { nodes(:opening) }
      assert_equal versions_id(:opening_en), node.version.id
    end

    should 'see a publication in the selected language' do
      visitor.lang = 'fr'
      node = secure!(Node) { nodes(:opening) }
      assert_equal versions_id(:opening_fr), node.version.id
    end

    should 'see a publication in the reference lang if there are none for the current language' do
      visitor.lang = 'de'
      node = secure!(Node) { nodes(:opening) }
      assert_equal 'fr', node.ref_lang
      assert_equal versions_id(:opening_fr), node.version.id
    end

    should 'see the list of editions' do
      # published versions
      node = secure!(Node) { nodes(:opening)  }
      assert_equal 2, node.editions.count
    end

    context 'when there is only a redaction for the current language' do
      setup do
        login(:tiger)
        version = secure!(Version) { versions(:opening_en) }
        @node = version.node
        assert @node.remove
        assert @node.destroy_version
      end

      subject do
        @node
      end

      should 'see a default publication' do
        login(:anon)
        node = secure!(Node) { nodes(:opening) }
        assert_equal versions_id(:opening_fr), node.version.id
      end

      should 'see other redaction and publication in another language ' do
        login(:tiger)
        # This test should live with destroy_version testing (relation reload test)
        assert_equal [:opening_red_fr, :opening_fr].map{|s| versions_id(s)}.sort, subject.versions.map{|v| v.id}.sort
      end
    end
  end # A visitor without write access

  context 'A visitor with write access' do
    setup do
      login(:ant)
    end

    should 'see a publication in the selected language' do
      visitor.lang = 'en'
      node = secure!(Node) { nodes(:opening) }
      assert_equal versions_id(:opening_en), node.version.id
    end

    should 'see a redaction in her language' do
      node = secure!(Node) { nodes(:opening) }
      assert_equal versions_id(:opening_red_fr), node.version.id
    end

    should 'see what he would see in the reference lang if there is nothing for the current language' do
      visitor.lang = 'de'
      node = secure!(Node) { nodes(:opening) }
      assert_equal 'fr', node.ref_lang
      assert_equal versions_id(:opening_red_fr), node.version.id
    end

    context 'in a language not supported' do
      setup do
        login(:tiger)
        version = secure!(Version) { versions(:opening_en) }
        @node = version.node
        assert @node.remove
        assert @node.destroy_version
      end

      should 'see a redaction from another language' do
        visitor.lang = 'de'
        node = secure!(Node) { nodes(:opening) }
        assert_equal versions_id(:opening_red_fr), node.version.id
      end

      should 'see redaction and publication from another language' do
        login(:tiger)
        # This test should live with destroy_version testing (relation reload test)
        assert_equal [:opening_red_fr, :opening_fr].map{|s| versions_id(s)}.sort, @node.versions.map{|v| v.id}.sort
      end
    end

    should 'see a redaction if there are no publications' do
      visitor.lang = 'de'
      node = secure!(Node) { nodes(:crocodiles) }
      assert_equal versions_id(:crocodiles_en), node.version.id
    end

    context 'on a node with replaced versions' do
      setup do
        login(:tiger)
        @node = secure!(Node) { nodes(:proposition) }
      end

      should 'see latest publication' do
        assert_equal versions_id(:proposition_en), @node.version.id
      end
    end # A visitor with write access in a language not supported
  end # A visitor with write access

  context 'A moderated visitor in write group' do
    setup do
      login(:ant)
      visitor.status = User::Status[:moderated]
    end

    context 'on an unpublished node' do
      setup do
        @node = secure!(Node) { nodes(:nature) }
      end

      should 'see the redaction' do
        assert_equal versions_id(:nature_red_en), @node.version.id
      end
    end

    context 'on a published node with a redaction' do
      setup do
        visitor.lang = 'fr'
        @node = secure(Node) { nodes(:opening) }
      end

      should 'see a redaction' do
        assert_equal versions_id(:opening_red_fr), @node.version.id
      end
    end


  end
  # =========== UPDATE VERSION TESTS =============

  context 'A visitor with write access' do

    context 'on a redaction' do

      context 'that she owns' do
        setup do
          login(:tiger)
          visitor.lang = 'fr'
        end

        subject do
          secure(Node) { nodes(:opening) }
        end

        should 'see own redaction' do
          # this is only to make sure fixtures are used correctly
          assert_equal Zena::Status[:red], subject.version.status
          assert_equal visitor.id, subject.version.user_id
        end

        context 'in redit time' do
          subject do
            secure(Page) { Page.create(:parent_id => nodes_id(:zena), :title => 'hop')}
          end

          should 'get a warning if editing would change original' do
            assert subject.would_change_original?
          end

          should 'not create a new redaction' do
            # Create page
            subject
            assert_difference('Version.count', 0) do
              # update in redit time
              assert subject.update_attributes(:title => 'Artificial Intelligence')
            end
          end
        end # in redit time

        context 'not in redit time' do
          should 'not get a warning if editing would change original' do
            assert !subject.would_change_original?
          end
        end # not in redit time

        should 'create a new redaction when editing out of redit time' do
          subject.version.created_at = Time.now.advance(:days => -1)
          assert_difference('Version.count', 1) do
            assert subject.update_attributes(:title => 'Einstein\'s brain mass is below average')
          end
        end

        should 'create a new redaction when using backup attribute' do
          assert_difference('Version.count', 1) do
            assert subject.update_attributes(:title => 'Einstein\'s brain mass is below average', :v_backup => 'true')
          end
        end

        should 'be allowed to propose' do
          assert subject.can_propose?
          assert subject.propose
          assert_equal Zena::Status[:prop], subject.version.status
        end

        should 'be allowed to remove' do
          assert subject.can_remove?
          assert subject.remove
          assert_equal Zena::Status[:rem], subject.version.status
        end
      end # A visitor with write access on a redaction ... that she owns

      context 'from another author' do
        setup do
          login(:ant)
          visitor.lang = 'fr'
        end

        subject do
          secure!(Node) { nodes(:opening) }
        end

        should 'see other author\'s redaction' do
          # this is only to make sure fixtures are used correctly
          assert_equal Zena::Status[:red], subject.version.status
          assert_not_equal visitor.id, subject.version.user_id
        end

        should 'not create a new redaction if all attributes are identical' do
          assert_difference('Version.count', 0) do
            assert subject.update_attributes(:title => subject.title, :text => subject.text)
          end
        end

        should 'replace redaction with a new one when updating attributes' do
          old_redaction_id = subject.version.id
          assert_difference('Version.count', 1) do
            assert subject.update_attributes(:title => 'Mon idée')
            assert_equal Zena::Status[:red], subject.version.status
          end
          old_redaction = Version.find(old_redaction_id)
          assert_equal Zena::Status[:rep], old_redaction.status
        end

        should 'be allowed to propose' do
          assert subject.can_propose?
          assert subject.propose
          assert_equal Zena::Status[:prop], subject.version.status
        end

        should 'not be allowed to publish' do
          assert !subject.can_publish?
          assert !subject.publish
          assert_equal 'You do not have the rights to publish.', subject.errors[:base]
        end

        should 'ignore v_status set to publish' do
          assert subject.update_attributes(:title => 'new title', :v_status => Zena::Status[:pub])
          assert_equal Zena::Status[:red], subject.version.status
        end
      end # A visitor with write access on a redaction from another author

      context 'in another lang' do
        setup do
          login(:ant)
          visitor.lang = 'fr'
        end

        subject do
          secure!(Node) { nodes(:crocodiles) }
        end

        should 'create a new redaction without altering original on edit' do
          assert_difference('Version.count', 1) do
            assert subject.update_attributes(:title => 'Alligators')
          end
          assert_equal Zena::Status[:red], versions(:crocodiles_en).status
        end
      end

    end # A visitor with write access on a redaction

    # -------------------- ON A PUBLICATION
    context 'on a publication' do
      setup do
        login(:ant)
      end

      subject do
        secure!(Node) { nodes(:status) }
      end

      should 'see a publication' do
        # this is only to make sure fixtures are used correctly
        assert_equal Zena::Status[:pub], subject.version.status
        assert !subject.new_record?
      end

      context 'that she owns' do
        setup do
          login(:lion)
        end

        subject do
          secure(Page) { Page.create(:parent_id => nodes_id(:zena), :title => 'hop', :v_status => Zena::Status[:pub]) }
        end

        should 'not get a warning if editing would change original' do
          assert !subject.would_change_original?
        end

        context 'in redit time' do
          subject do
            secure(Page) { Page.create(:parent_id => nodes_id(:zena), :title => 'hop', :v_status => Zena::Status[:pub])}
          end

          should 'create a new redaction on edit' do
            # create page and make sure it is published
            assert_equal Zena::Status[:pub], subject.v_status
            # reload
            page = secure(Node) { Node.find(subject.id) }
            assert_difference('Version.count', 1) do
              page.update_attributes(:title => 'hip')
            end
          end
        end # in redit time

      end # that she owns

      should 'not get a warning if editing would change original' do
        assert !subject.would_change_original?
      end

      should 'be allowed to edit' do
        assert subject.can_edit?
      end

      should 'create a redaction when updating attributes' do
        assert_difference('Version.count', 1) do
          assert subject.update_attributes(:title => 'The Technique Of Orchestration')
        end
      end

      should 'not alter current publication when editing' do
        visitor.lang = 'en'
        assert subject.update_attributes(:title => 'AI magazine')
        assert_equal Zena::Status[:pub], versions(:status_en).status
      end

      should 'be able to write new attributes using properties' do
        assert_difference('Version.count', 1) do
          node = secure!(Node) { nodes(:lake) }
          assert node.update_attributes(:first_name => 'Mea Lua', :country => 'Brazil')
          node = secure!(Node) { nodes(:lake) } # reload
          assert_equal 'Mea Lua we love', node.title
          assert_equal 'Brazil', node.prop['country']
        end
      end

      should 'be able to create nodes using properties' do
        node = secure!(Node) { Node.create(defaults.merge(:title => 'Pandeiro')) }
        assert_equal 'Pandeiro', node.title
      end

      should 'create a new redaction when setting version_attributes' do
        subject.version_attributes = {'lang' => 'de'}
        assert_equal 'de', subject.version.lang
        assert_difference('Version.count', 1) do
          assert subject.save
          assert subject.version.cloned?
        end
      end

      should 'create versions in the current language' do
        visitor.lang = 'de'
        subject.update_attributes('title' => 'Sein und Zeit')
        assert_equal 'de', subject.version.lang
      end

      should 'not be allowed to propose' do
        assert !subject.can_propose?
        assert !subject.propose # does nothing
      end

      should 'not be allowed to publish' do
        assert !subject.can_publish?
        assert !subject.publish
        assert_equal 'Already published.', subject.errors[:base]
      end

      should 'not be allowed to unpublish' do
        assert !subject.can_remove?
        assert !subject.can_unpublish?
        assert !subject.unpublish
        assert_equal 'You do not have the rights to unpublish.', subject.errors[:base]
      end
    end # A visitor with write access on a publication


    # -------------------- ON A PROPOSITION
    context 'on a proposition' do
      setup do
        login(:ant)
        visitor.lang = 'fr'
        node = secure!(Node) { nodes(:opening) }
        node.propose
      end

      subject do
        secure!(Node) { nodes(:opening) } # reload
      end

      should 'see a proposition.' do
        # this is only to make sure fixtures are used correctly
        assert_equal Zena::Status[:prop], subject.version.status
      end

      should 'not be allowed to update' do
        assert !subject.can_edit?
        assert !subject.update_attributes(:title => 'foobar')
        assert_equal 'You cannot edit while a proposition is beeing reviewed.', subject.errors[:base]
      end

      should 'not be allowed to propose' do
        assert !subject.can_propose?
        assert !subject.propose
        assert 'Already proposed.', subject.errors[:base]
      end

      should 'not be allowed to publish' do
        assert !subject.can_publish?
        assert !subject.publish
        assert_equal 'You do not have the rights to publish.', subject.errors[:base]
      end

      should 'not be allowed to remove' do
        assert !subject.can_remove?
        assert !subject.remove
        assert_equal 'You should refuse the proposition before removing it.', subject.errors[:base]
      end

      should 'not be allowed to refuse' do
        assert !subject.can_refuse?
        assert !subject.refuse
        assert_equal 'You do not have the rights to refuse.', subject.errors[:base]
      end
    end # A visitor with write access on a proposition

    context 'on a site with autopublish' do
      setup do
        login(:ant)
        visitor.site.auto_publish = true
      end

      should 'create redactions' do
        node = secure!(Node) { Node.create( :parent_id => nodes_id(:zena), :title => 'This one should not autopublish' ) }
        assert !node.new_record?
        assert_equal Zena::Status[:red], node.version.status
      end
    end
  end # A visitor with write access


  context 'A visitor with drive access' do

    setup do
      login(:tiger)
    end

    context 'on a redaction' do
      subject do
        secure!(Node) { nodes(:crocodiles) }
      end

      should 'see a redaction' do
        # this is only to make sure fixtures are used correctly
        assert_equal Zena::Status[:red], subject.version.status
      end

      should 'be allowed to propose' do
        assert subject.can_propose?
        assert subject.propose
        assert_equal Zena::Status[:prop], subject.version.status
      end

      should 'be allowed to publish' do
        assert subject.can_publish?
        assert subject.publish
        assert_equal Zena::Status[:pub], subject.version.status
      end

      should 'be allowed to remove' do
        assert subject.can_remove?
        assert subject.remove
        assert_equal Zena::Status[:rem], subject.version.status
      end
    end # A visitor with drive access on a redaction

    # -------------------- ON A PUBLICATION
    context 'on a publication' do
      subject do
        secure!(Node) { nodes(:status) }
      end

      should 'see a publication' do
        # this is only to make sure fixtures are used correctly
        assert_equal Zena::Status[:pub], subject.version.status
      end

      should 'not be allowed to propose' do
        assert !subject.can_propose?
        assert !subject.propose
        assert_equal 'This transition is not allowed.', subject.errors[:base]
      end

      should 'not be allowed to publish' do
        assert !subject.can_publish?
        assert !subject.publish
        assert_equal 'Already published.', subject.errors[:base]
      end

      should 'be allowed to unpublish' do
        assert subject.can_unpublish?
        assert subject.unpublish
        assert_equal Zena::Status[:rem], subject.version.status
      end

      should 'see an up-to-date versions list after unpublish' do
        subject = secure!(Node) { nodes(:opening) }
        assert subject.unpublish
        versions = subject.versions
        assert_equal Zena::Status[:rem], versions.detect {|v| v.id == versions_id(:opening_en)}.status
        assert_equal Zena::Status[:pub], versions.detect {|v| v.id == versions_id(:opening_fr)}.status
        assert_equal Zena::Status[:red], versions.detect {|v| v.id == versions_id(:opening_red_fr)}.status
      end

      should 'not be allowed to refuse' do
        assert !subject.can_refuse?
        assert !subject.refuse
        assert_equal 'You do not have the rights to edit.', subject.errors[:base]
      end

      should 'replace a redaction when re editing a removed version' do
        subject = secure!(Node) { nodes(:opening) }
        subject.version = versions(:opening_fr)
        visitor.lang = 'fr'
        assert subject.remove
        assert subject.redit
        assert_equal Zena::Status[:red], Version.find(subject.version_id).status
        assert_equal Zena::Status[:rep], versions(:opening_red_fr).status
      end

      should 'not see that she can remove' do
        assert !subject.can_remove?
        assert subject.remove
        assert_equal Zena::Status[:rem], Version.find(subject.version.id).status
      end

      context 'that she owns' do
        subject do
          secure!(Node) { nodes(:collections) }
        end

        context 'on a site with autopublish' do
          setup do
            visitor.site.auto_publish = true
          end

          should 'not create a new publication when autopublishing in redit time' do
            assert_difference('Version.count', 0) do
              subject.version.created_at = Time.now
              assert subject.update_attributes(:title => 'We have no ideas if prehistoric women stayed at home.')
              assert_equal Zena::Status[:pub], subject.version.status
            end
          end

          should 'create a new publication when autopublishing out of redit time' do
            assert_difference('Version.count', 1) do
              assert subject.update_attributes(:title => 'Larry Summers is a jerk.')
            end
          end

          should 'replace old publication when autopublishing' do
            subject.update_attributes(:title => 'Is not very apt at the high end.')
            assert_equal Zena::Status[:rep], versions(:collections_en).status
          end
        end

        context 'setting v_status to autopublish' do

          should 'not create a new publication in redit time' do
            assert_difference('Version.count', 0) do
              subject.version.created_at = Time.now
              assert subject.update_attributes(:title => 'Flat brains.', :v_status => Zena::Status[:pub])
            end
          end

          should 'create a new publication out of redit time' do
            assert_difference('Version.count', 1) do
              assert subject.update_attributes(:title => 'Equal.', :v_status => Zena::Status[:pub])
            end
          end
        end # setting v_status to autopublish
      end # that she owns
      
      # Basic tests for property integration in Node.
      context 'changing attributes' do
        should 'mark version as edited' do
          subject.attributes = {'title' => 'foo'}
          assert subject.version.edited?
        end
        
        should 'mark properties as changed' do
          subject.attributes = {'title' => 'foo'}
          assert subject.prop.changed?
        end
        
        should 'show property changes on chages' do
          subject.attributes = {'title' => 'foo'}
          assert_equal Hash['title'=> ['status title', 'foo']], subject.changes
        end
      end # changing attributes
      
    end # A visitor with drive access on a publication


    # -------------------- ON A PROPOSITION
    context 'on a proposition' do
      setup do
        login(:tiger)
      end

      subject do
        node = secure!(Node) { nodes(:status) }
        node.update_attributes(:title => 'Sambal Oelek')
        assert node.propose
        secure!(Node) { nodes(:status) } # reload
      end

      should 'see a proposition' do
        # this is only to make sure fixtures are used correctly
        assert_equal Zena::Status[:prop], subject.version.status
      end

      should 'not be allowed to propose' do
        assert !subject.can_propose?
        assert !subject.propose
        assert 'Already proposed.', subject.errors[:base]
      end

      should 'be allowed to publish' do
        assert subject.can_publish?
        assert subject.publish
        assert_equal Zena::Status[:pub], subject.version.status
      end

      should 'be allowed to publish by setting status attribute' do
        assert subject.update_attributes(:v_status => Zena::Status[:pub])
        assert_equal Zena::Status[:pub], subject.version.status
      end

      should 'be allowed to publish with a custom date' do
        assert subject.update_attributes(:v_status => Zena::Status[:pub], :v_publish_from => '2007-01-03')
        assert_equal Time.gm(2007,1,3), subject.version.publish_from
      end

      should 'not be allowed to publish and change attributes other then publish_from' do
        assert !subject.update_attributes(:v_status => Zena::Status[:pub], :title => 'I hack my own !')
        assert_equal "You do not have the rights to change a proposition's attributes.", subject.errors[:base]
      end

      should 'replace old publication on publish' do
        subject.publish
        assert_equal Zena::Status[:rep], versions(:status_en).status
      end

      should 'see an up-to-date versions list after publish' do
        subject.publish
        pub_v_id = subject.version.id
        versions = subject.versions
        assert_equal Zena::Status[:pub], versions.detect {|v| v.id == pub_v_id }.status
        assert_equal Zena::Status[:rep], versions.detect {|v| v.id == versions_id(:status_en) }.status
        assert_equal Zena::Status[:pub], versions.detect {|v| v.id == versions_id(:status_fr) }.status
      end

      should 'be allowed to refuse' do
        assert subject.can_refuse?
        assert subject.refuse
        assert_equal Zena::Status[:red], subject.version.status
      end

      should 'not be allowed to remove' do
        assert !subject.can_remove?
        assert !subject.remove
        assert_equal 'You should refuse the proposition before removing it.', subject.errors[:base]
      end

      should 'not be allowed to unpublish' do
        assert !subject.can_unpublish?
      end

      context 'from another author' do
        setup do
          login(:lion)
        end

        should 'be allowed to publish with a custom date anterior to the first publication' do
          subject.update_attributes(:v_status => Zena::Status[:pub], :v_publish_from => '1800-01-03')
          assert_equal Time.gm(1800,1,3), subject.version.publish_from
          assert_equal Time.gm(1800,1,3), subject.publish_from
        end

        should 'be allowed to publish with a custom date' do
          assert subject.update_attributes(:v_status => Zena::Status[:pub], :v_publish_from => '2007-01-03')
          assert_equal Time.gm(2007,1,3), subject.version.publish_from
          assert_equal Time.gm(2006,3,10), subject.publish_from # keeps min publication date
        end

        should 'not be allowed to publish and change attributes other then publish_from' do
          assert !subject.update_attributes(:v_status => Zena::Status[:pub], :title => 'I hack you !')
          assert_equal "You do not have the rights to change a proposition's attributes.", subject.errors[:base]
        end
      end

    end # A visitor with drive access on a proposition

    context 'on a removed version' do
      setup do
        login(:lion)
      end

      subject do
        # status_en => removed
        # status_fr => removed
        Node.connection.execute "UPDATE versions SET publish_from = NULL, status = #{Zena::Status[:rem]} WHERE id IN (#{versions_id(:status_en)},#{versions_id(:status_fr)})"
        vhash = {'r' => {}, 'w' => {'fr' => versions_id(:status_fr), 'en' => versions_id(:status_en)}}
        Node.connection.execute "UPDATE nodes SET publish_from = NULL, vhash = '#{vhash.to_json}'"
        secure!(Node) { nodes(:status) }
      end

      should 'see a removed version' do
        # Just to make sure our setup is ok
        assert_equal Zena::Status[:rem], subject.version.status
      end

      should 'see any other version when destroying version' do
        assert_difference('Version.count', -1) do
          assert subject.destroy_version
        end
        assert_equal versions_id(:status_fr), subject.version_id
        subject = secure!(Node) { nodes(:status) } # reload
        assert_equal versions_id(:status_fr), subject.version_id
      end

      should 'be allowed to redit' do
        assert subject.can_apply?(:redit)
        assert subject.redit
        assert_equal Zena::Status[:red], subject.version.status
      end

      context 'with a publication in same lang' do
        setup do
          rem_version   = subject.version
          subject.version = nil
          subject.update_attributes(:v_status => Zena::Status[:pub], :title => 'publication in en')
          @v_pub_id = subject.version.id
          subject.version = rem_version
        end

        should 'not alter publication on redit' do
          assert subject.redit
          assert_equal Zena::Status[:pub], Version.find(@v_pub_id).status
        end
      end

    end # A visitor with drive access on a removed version

    context 'on a site with autopublish' do
      setup do
        login(:lion)
        visitor.site.auto_publish = true
      end

      should 'create published nodes' do
        node = secure!(Node) { Node.create( :parent_id => nodes_id(:zena), :title => 'This one should auto publish' ) }
        assert !node.new_record?
        assert_equal Zena::Status[:pub], node.version.status
      end
    end
  end # A visitor with drive access

  # =========== OLD TESTS TO REWRITE =============


  def test_unpublish_all
    login(:tiger)
    visitor.lang = 'fr'
    node = secure!(Node) { nodes(:status)  }
    assert node.unpublish # remove publication
    assert_equal Zena::Status[:rem], node.version.status

    # tiger is a writer, he sees the removed version
    node = secure!(Node) { nodes(:status)  }
    assert_equal Zena::Status[:rem], node.version.status
  end

  def test_can_man_cannot_publish
    login(:ant)
    node = secure!(Note) { Note.create(:title => 'hello', :parent_id=>nodes_id(:cleanWater)) }
    assert !node.new_record?
    assert node.can_drive?, "Can drive"
    assert node.can_drive?, "Can manage"
    assert !node.can_publish?, "Cannot publish"
    assert !node.publish, "Cannot publish"

    node.update_attributes(:inherit=>-1, :v_status => Zena::Status[:red]) # previous 'node.publish' tried to publish node

    assert node.can_drive?, "Can drive"
    assert !node.can_publish?, "Cannot publish"
  end

  def test_unpublish
    login(:lion)
    node = secure!(Node) { nodes(:bananas)  }
    assert node.unpublish # unpublish version
    assert_equal Zena::Status[:rem], node.version.status
  end

  def test_can_unpublish_version
    login(:lion)
    node = secure!(Node) { nodes(:lion) }
    pub_version = node.version
    assert node.can_unpublish?
    assert node.update_attributes(:name => 'Leopard')
    assert_equal Zena::Status[:red], node.version.status
    assert !node.can_unpublish?
  end

  def test_remove_redaction
    login(:tiger)
    visitor.lang = 'en'
    node = secure!(Node) { nodes(:lake) }
    assert node.can_drive?
    assert_equal Zena::Status[:red], node.version.status
    assert_equal versions_id(:lake_red_en), node.version.id
    assert node.remove
    assert_equal Zena::Status[:rem], node.version.status
  end

  def test_not_owner_can_remove
    Node.connection.execute "DELETE FROM data_entries"
    login(:lion)
    node = secure!(Node) { nodes(:status) }
    assert_equal users_id(:ant), node.user_id
    assert node.can_apply?(:unpublish)
    assert node.unpublish
    assert node.can_apply?(:destroy_version)
    assert node.destroy_version
    # second version
    node = secure!(Node) { nodes(:status) }
    assert_equal users_id(:ant), node.user_id
    assert node.can_apply?(:unpublish)
    assert node.unpublish
    assert node.can_apply?(:destroy_version)
    assert node.destroy_version
    assert_raise(ActiveRecord::RecordNotFound) { nodes(:status) }
  end

  def test_traductions
    login(:lion) # lang = 'en'
    node = secure!(Node) { nodes(:status) }
    trad = node.traductions
    assert_equal 2, trad.size
    trad_node = trad[0].node
    assert_equal node.object_id, trad_node.target.object_id # make sure object is not reloaded and is secured
    assert_equal 'en', node.version.lang
    assert_equal 'fr', trad[1][:lang]
    node = secure!(Node) { nodes(:wiki) }
    trad = node.traductions
    assert_equal 1, trad.size
  end

  def test_root_never_empty
    login(:lion)
    Node.connection.execute "UPDATE nodes SET parent_id = NULL WHERE parent_id = #{nodes_id(:zena)}"
    node = secure!(Node) { nodes(:zena) }
    assert !node.empty?
  end

  def test_empty?
    login(:lion)
    Node.connection.execute "DELETE FROM data_entries"
    Node.connection.execute "UPDATE nodes SET parent_id = NULL WHERE parent_id = #{nodes_id(:people)} AND id <> #{nodes_id(:ant)}"
    node = secure!(Node) { nodes(:people) }
    assert_not_nil node.find(:all, 'nodes')
    assert !node.empty?
    Node.connection.execute "UPDATE nodes SET parent_id = NULL WHERE parent_id = #{nodes_id(:people)}"
    node = secure!(Node) { nodes(:people) }
    assert node.empty?
  end

  def test_destroy
    login(:lion)
    node = secure!(Node) { nodes(:talk) }
    sub  = secure!(Page) { Page.create(:parent_id => nodes_id(:talk), :title => 'hello') }
    assert node.update_attributes(:title => 'new title')
    assert node.publish

    node = secure!(Node) { nodes(:talk) }
    assert !sub.new_record?
    assert_equal 2, node.versions.size
    assert_equal 1, node.send(:all_children).size

    assert !node.can_destroy_version? # versions are not in 'deleted' status
    Node.connection.execute "UPDATE versions SET status = #{Zena::Status[:rem]} WHERE node_id = #{nodes_id(:talk)}"
    node = secure!(Node) { nodes(:talk) } # reload
    assert node.can_destroy_version? # versions are now in 'deleted' status
    assert node.destroy_version      # 1 version left
    assert_equal 1, node.versions.size

    assert !node.destroy

    assert_equal "cannot be removed (contains subpages or data)", node.errors[:base]

    node = secure!(Node) { nodes(:talk) } # reload
    assert_equal 1, node.versions.size

    assert sub.remove
    assert_equal 1, node.versions.size

    assert sub.destroy_version # destroy all
    node = secure!(Node) { nodes(:talk) } # reload

    assert node.empty?

    assert node.can_destroy_version?
    assert node.destroy_version # destroy all
    assert_raise(ActiveRecord::RecordNotFound) { nodes(:talk) }
  end

  def test_auto_publish_by_status
    # set v_status = 50 ===> publish
    login(:lion)
    node = secure!(Node) { nodes(:status) }
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 'status title', node.title
    assert_equal 1, node.version.number
    assert_equal 2, node.versions.size
    node.update_attributes(:title => "Statues are better", 'v_status' => Zena::Status[:pub])
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 3, node.version.number
    assert_equal 'Statues are better', node.title
  end

  def test_update_auto_publish_set_v_publish_from_to_nil
    Site.connection.execute "UPDATE sites set auto_publish = #{Zena::Db::TRUE}, redit_time = 7200 WHERE id = #{sites_id(:zena)}"
    login(:tiger)
    node = secure!(Node) { Node.create( :parent_id => nodes_id(:zena), :title => "This one should auto publish" ) }
    node = secure!(Node) { Node.find(node.id) } # reload
    node.update_attributes(:title => "This one should not be gone",  :v_publish_from => "")
    assert_equal 'This one should not be gone', node.title
    assert_equal Zena::Status[:pub], node.version.status
    assert_not_nil node.publish_from
    assert node.publish_from > Time.now - 10
    assert node.publish_from < Time.now + 10
    assert node.version.publish_from > Time.now - 10
    assert node.version.publish_from < Time.now + 10
  end

  def test_auto_publish_in_redit_time_can_publish
    # set site.auto_publish      ===> publish
    # now < created + redit_time ===> update current publication
    Site.connection.execute "UPDATE sites set auto_publish = #{Zena::Db::TRUE}, redit_time = 7200 WHERE id = #{sites_id(:zena)}"
    Version.connection.execute "UPDATE versions set created_at = '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{versions_id(:tiger_en)}"
    login(:tiger)
    visitor.lang = 'en'
    node = secure!(Node) { nodes(:tiger) }
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 'Panthera Tigris Sumatran', node.title
    assert_equal 1, node.version.number
    assert_equal users_id(:tiger), node.version.user_id
    assert node.version.created_at < Time.now + 600
    assert node.version.created_at > Time.now - 600
    assert node.update_attributes(:name => "Puma")
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 1, node.version.number
    assert_equal versions_id(:tiger_en), node.version.id
    assert_equal 'Panthera Puma', node.title
  end

  def test_publish_after_save_in_redit_time_can_publish
    # set site.auto_publish      ===> publish
    # now < updated + redit_time ===> update current publication
    Site.connection.execute "UPDATE sites set auto_publish = #{Zena::Db::TRUE}, redit_time = 7200 WHERE id = #{sites_id(:zena)}"
    Version.connection.execute "UPDATE versions set created_at = '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}' WHERE id = #{versions_id(:tiger_en)}"
    login(:tiger)
    visitor.lang = 'en'
    node = secure!(Node) { nodes(:tiger) }
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 'Panthera Tigris Sumatran', node.title
    assert_equal 1, node.version.number
    assert_equal users_id(:tiger), node.version.user_id
    assert node.version.created_at < Time.now + 600
    assert node.version.created_at > Time.now - 600
    assert node.update_attributes(:name => "Puma", :v_status => Zena::Status[:pub])
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 1, node.version.number
    assert_equal versions_id(:tiger_en), node.version.id
    assert_equal 'Panthera Puma', node.title
  end


  def test_create_auto_publish_v_publish_from_to_nil
    Site.connection.execute "UPDATE sites set auto_publish = #{Zena::Db::TRUE}, redit_time = 7200 WHERE id = #{sites_id(:zena)}"
    login(:tiger)
    node = secure!(Node) { Node.create( :parent_id => nodes_id(:zena), :title => "This one should auto publish", :v_publish_from => nil ) }
    assert ! node.new_record? , "Not a new record"
    assert ! node.version.new_record? , "Not a new redaction"
    assert_equal Zena::Status[:pub], node.version.status, "published version"
    assert node.publish_from > Time.now - 10
    assert node.publish_from < Time.now + 10
    assert node.version.publish_from > Time.now - 10
    assert node.version.publish_from < Time.now + 10
    assert_equal "This one should auto publish", node.title
  end

  def test_set_v_lang_publish
    # publish should replace published item in v_lang
    login(:tiger)
    node = secure!(Node) { nodes(:opening) }
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 'en', node.version.lang
    pub_v_en = node.version.id
    visitor.lang = 'fr'
    node = secure!(Node) { nodes(:opening) }
    assert_equal Zena::Status[:red], node.version.status
    assert_equal 'fr', node.version.lang
    assert node.update_attributes(:v_lang => 'en', :v_status => Zena::Status[:pub])
    assert_not_equal node.version.id, pub_v_en
    assert_equal Zena::Status[:pub], node.version.status
    assert_equal 'en', node.version.lang
    old_version = Version.find(pub_v_en)
    assert_equal Zena::Status[:rep], old_version.status
  end

  def test_auto_publish_no_publish_rights
    Site.connection.execute "UPDATE sites set auto_publish = #{Zena::Db::TRUE}, redit_time = 0 WHERE id = #{sites_id(:zena)}"
    login(:ant)
    node = secure!(Node) { nodes(:cleanWater) }
    assert !node.can_publish?
    assert node.update_attributes(:title => 'bloated waters')
    assert_equal Zena::Status[:red], node.version.status
  end

  def test_status
    login(:tiger)
    node = secure!(Node) { Node.new(defaults) }

    assert node.save
    assert_equal Zena::Status[:red], node.version.status
    assert node.propose
    assert_equal Zena::Status[:prop], node.version.status
    assert node.publish
    assert_equal Zena::Status[:pub], node.version.status
    assert node.publish_from <= Time.now, 'node publish_from is smaller the Time.now'
    login(:ant)
    assert_nothing_raised { node = secure!(Node) { Node.find(node.id) } }
    assert node.update_attributes(:summary=>'hello my friends'), "Can create a new edition"
    assert_equal Zena::Status[:red], node.version.status
    assert node.propose
    assert_equal Zena::Status[:prop], node.version.status
    # WE CAN USE THIS TO TEST vhash (version hash cache) when it's implemented
  end

  def test_publish_with_v_status
    login(:tiger)
    node = secure!(Node) { nodes(:cleanWater)  }
    assert node.update_attributes(:title => 'dirty')
    node = secure!(Node) { nodes(:cleanWater)  }
    assert_equal Zena::Status[:red], node.version.status
    assert node.update_attributes(:v_status => Zena::Status[:pub])
    node = secure!(Node) { nodes(:cleanWater)  }
    assert_equal Zena::Status[:pub], node.version.status
  end

  def test_transition_allowed
    login(:tiger) # can do everything
    node = secure!(Node) { nodes(:status) }
    assert node.can_apply?(:edit)
  end
end
