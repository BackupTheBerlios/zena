require File.dirname(__FILE__) + '/../test_helper'

class ApplicationHelperTest < ZenaTestHelper
  include ApplicationHelper

  def setup
    @controllerClass = ApplicationController
    super
    login(:anon)
  end
  
  # We have to define section this way in order to share with the StubController. I do not understand why we need to do this, but
  # it works. If anyone has a better idea...
  def session
    @response.session
  end
  
  def test_nodes_id
    assert_equal nodes(:zena)[:id], nodes_id(:zena)
  end
  
  def test_zen_path
    
    login(:ant)
    params[:format] = 'html'
    node = secure(Node) { nodes(:zena) }
    assert_equal "/oo", zen_path(node)
    assert_equal "/oo/project11_test.html", zen_path(node, :mode=>'test')
    
    login(:anon)
    params[:format] = 'html'
    node = secure(Node) { nodes(:zena) }
    assert_equal "/en", zen_path(node)
    assert_equal "/en/project11_test.html", zen_path(node, :mode=>'test')
    node = secure(Node) { nodes(:people) }
    assert_equal "/en/section12.html", zen_path(node)
    assert_equal "/en/section12_test.html", zen_path(node, :mode=>'test')
    assert_equal "/tt/section12_test.jpg", zen_path(node, :mode=>'test', :prefix=>'tt', :format=>'jpg')
    node = secure(Node) { nodes(:cleanWater) }
    assert_equal "/en/projects/cleanWater.html", zen_path(node)
    assert_equal "/en/projects/cleanWater_test.html", zen_path(node, :mode=>'test')
    node = secure(Node) { nodes(:status) }
    assert_equal "/en/projects/cleanWater/page22.html", zen_path(node)
    assert_equal "/en/projects/cleanWater/page22_test.html", zen_path(node, :mode=>'test')
  end
  
  def test_zen_url
    params[:format] = 'html'
    node = secure(Node) { nodes(:zena) }
    assert_equal "http://test.host/en", zen_url(node)
    assert_equal "http://test.host/en/project11_test.html", zen_url(node, :mode=>'test')
  end
  
  
  def test_img_tag
    login(:ant)
    img = secure(Node) { nodes(:bird_jpg) }
    assert_equal "<img src='/oo/image30.jpg' width='661' height='600' alt='bird' class='full'/>", img_tag(img)
    assert_equal "<img src='/oo/image30_pv.jpg' width='70' height='70' alt='bird' class='pv'/>", img_tag(img, :mode=>'pv')
  end
  
  def test_img_tag_document
    login(:ant)
    doc = secure(Node) { nodes(:water_pdf) }
    assert_equal "<img src='/images/ext/pdf.png' width='32' height='32' alt='pdf document' class='doc'/>", img_tag(doc)
    assert_equal "<img src='/images/ext/pdf_pv.png' width='70' height='70' alt='pdf document' class='doc'/>",  img_tag(doc, :mode=>'pv')
  end
  
  def test_img_tag_opts
    login(:anon)
    img = secure(Node) { nodes(:bird_jpg) }
    assert_equal "<img src='/en/image30.jpg' width='661' height='600' alt='bird' id='yo' class='full'/>",
                  img_tag(img, :mode=>nil, :id=>'yo')
    assert_equal "<img src='/en/image30_pv.jpg' width='70' height='70' alt='bird' id='yo' class='super'/>",
                  img_tag(img, :mode=>'pv', :id=>'yo', :class=>'super')
    assert_equal "<img src='/en/image30_med.jpg' width='205' height='186' alt='super man' class='med'/>",
                  img_tag(img, :mode=>'med', :alt=>'super man')
  end
  
  def test_img_tag_other
    login(:tiger)
    doc = secure(Node) { nodes(:water_pdf) }
    doc.c_ext = 'bin'
    assert_equal 'pdf', doc.c_ext
    doc.version.content[:ext] = 'bin'
    assert_equal 'bin', doc.c_ext
    assert_equal "<img src='/images/ext/other.png' width='32' height='32' alt='water' class='doc'/>", img_tag(doc)
    assert_equal "<img src='/images/ext/other_pv.png' width='70' height='70' alt='water' class='doc'/>", img_tag(doc, :mode=>'pv')
    assert_equal "<img src='/images/ext/other_std.png' width='32' height='32' alt='water' class='doc'/>", img_tag(doc, :mode=>'std')
  end
  
  def test_alt_with_apos
    doc = secure(Node) { nodes(:lake_jpg) }
    assert_equal "<img src='/en/projects/cleanWater/image24.jpg' width='600' height='440' alt='it&apos;s a lake' class='full'/>", img_tag(doc)
  end
  
  def test_uses_calendar_with_lang
    res = uses_calendar
    assert_match %r{/calendar/lang/calendar-en-utf8.js}, res
  end
  
  def test_uses_calendar_without_lang
    visitor.lang = 'io'
    res = uses_calendar
    assert_no_match %r{/calendar/lang/calendar-io-utf8.js}, res
    assert_match %r{/calendar/lang/calendar-en-utf8.js}, res
  end
  
  def test_link_box
    @node = secure(Node) { nodes(:letter) }
    assert_equal "<ul class='link_box'><li><b>calendars</b></li><li><input type='checkbox' name='node[calendar_ids][]' value='29' class='box' />wiki</li></ul>", link_box('node', :calendars)
    login(:tiger)
    @node = secure(Node) { nodes(:letter) }
    assert_match %r{ul class='link_box'.*node\[calendar_ids\]\[\].*11.*19.*21.*29}, link_box('node', :calendars)
    assert_match %r{node\[hot_for_ids\]\[\].*21.*29}, link_box('node', :hot_for, :in=>[11,19,13])
    assert_no_match %r{23}, link_box('node', :hot_for, :in=>[11,19,13])
    @node = secure(Node) { nodes(:cleanWater) }
    assert_match %r{node\[hot_id\].*22}, link_box('node', :hot)
  end 
  
  def test_select_id
    @node = secure(Node) { nodes(:status) }
    select = select_id('node', :parent_id, :class=>'Project')
    assert_no_match %r{select.*node\[parent_id\].*21.*19.*29.*11}m, select
    assert_match %r{select.*node\[parent_id\].*29}, select
    login(:tiger)
    @node = secure(Node) { nodes(:status) }
    assert_match %r{select.*node\[parent_id\].*21.*19.*29.*11}m, select_id('node', :parent_id, :class=>'Project')
    assert_match %r{input type='text'.*node\[icon_id\].*node_icon_id_name}m, select_id('node', :icon_id)
  end
  
  def test_date_box
    @node = secure(Node) { nodes(:status) }
    assert_match %r{div class="date_box".*img src="\/calendar\/iconCalendar.gif".*input class="updated_at" id="datef.*" name="node\[updated_at\]" size="30" type="text" value="2006-04-11 01:00"}m, date_box('node', 'updated_at')
  end
  
  def test_javascript
    assert_nothing_raised { javascript('test') }
  end
  
  def test_tlink_to_remote
    visitor.lang = 'fr'
    assert_equal "<a href=\"#\" onclick=\"new Ajax.Request('/nodes/12/versions/1/publish', {asynchronous:true, evalScripts:true}); return false;\">lundi</a>", tlink_to_remote('Monday', :url=>publish_version_path(:node_id => 12, :id => 1))
  end
  
  def test_tlink_to
    visitor.lang = 'fr'
    assert_equal "<a href=\"/nodes/12/versions/1/edit\">lundi</a>", tlink_to('Monday', edit_version_path(:node_id=>12, :id=>1))
  end
  
  def test_tlink_to_function
    visitor.lang = 'fr'
    assert_equal "<a href=\"new Element.hide('drive')\">lundi</a>", tlink_to('Monday', "new Element.hide('drive')")
  end
  
  def test_transb
    set_session[:translate] = true
    assert_equal trans('Monday',:edit => false), transb('Monday')
    assert_not_equal 'lundi', trans('Monday')
  end
  
  def test_rnd
    assert ((Time.now.to_i-1 <= rnd) && (rnd <= Time.now.to_i+2))
  end
  
  def test_login_link
    assert_equal "<a href='/login'>login</a>", login_link
    login(:ant)
    assert_equal "<a href='/logout'>logout</a>", login_link
  end
  
  def test_trans
    assert_equal 'yoba', trans('yoba')
    assert_equal '%A, %B %d %Y', trans('full_date')
    visitor.lang = 'fr'
    assert_equal '%A, %d %B %Y', trans('full_date')
    visitor.lang = 'io'
    assert_equal '%A, %B %d %Y', trans('full_date')
    session[:translate] = true
    assert_match /div.*phrase75.*Ajax.*\%A, \%B \%d \%Y/, trans('full_date')
  end
  # ======================== tests pass to here ================
  def test_long_time
    atime = visitor.tz.unadjust(Time.gm(2006,11,10,17,42,25)) # local time for visitor
    assert_equal "17:42:25", long_time(atime)
    visitor.lang = 'fr'
    assert_equal "17:42:25 ", long_time(atime)
  end
  
  def test_short_time
    atime = visitor.tz.unadjust(Time.gm(2006,11,10,17,33))
    assert_equal "17:33", short_time(atime)
    visitor.lang = 'fr'
    assert_equal "17h33", short_time(atime)
  end

  def test_long_date
    atime = visitor.tz.unadjust(Time.gm(2006,11,10))
    assert_equal "2006-11-10", long_date(atime)
    visitor.lang = 'fr'
    assert_equal "10.11.2006", long_date(atime)
  end

  def test_full_date
    atime = visitor.tz.unadjust(Time.gm(2006,11,10))
    assert_equal "Friday, November 10 2006", full_date(atime)
    visitor.lang = 'fr'
    assert_equal "vendredi, 10 novembre 2006", full_date(atime)
  end
  
  def test_short_date
    atime = Time.now
    assert_equal atime.strftime('%m.%d'), short_date(atime)
    visitor.lang = 'fr'
    assert_equal atime.strftime('%d.%m'), short_date(atime)
  end
  
  def test_format_date
    atime = Time.now
    assert_equal atime.strftime('%m.%d'), tformat_date(atime, 'short_date')
    visitor.lang = 'fr'
    assert_equal atime.strftime('%d.%m'), tformat_date(atime, 'short_date')
  end
  
  def test_parse_date
    assert_equal Time.gm(2006,11,10), parse_date('2006-11-10', '%Y-%m-%d')
    assert_equal Time.gm(2006,11,10), parse_date('10.11 2006', '%d.%m %Y')
    assert_equal Time.gm(2006,11,10), parse_date('10.11 / 06', '%d.%m.%y')
    assert_equal Time.gm(Time.now.year,11,10), parse_date('11-10', '%m.%d')
  end
  
  def test_parse_date_time
    assert_equal Time.gm(2006,11,10,12,30), parse_date('2006-11-10 12:30', '%Y-%m-%d %H:%M')
    assert_equal Time.gm(2006,11,10,12,30), parse_date('2006-11-10 12:30')
    assert_equal Time.gm(2006,11,10,12,30), parse_date('10.11.2006 12:30', '%d.%m.%Y %H:%M')
  end
  
  def test_visitor_link
    assert_equal '', visitor_link
    login(:ant)
    assert_match /div id='visitor'.*home.*Solenopsis Invicta/, visitor_link
  end
  
  def test_flash_messages
    login(:ant)
    assert_equal '', flash_messages(:both)
    flash[:notice] = 'yoba'
    assert_match /notice.*yoba/, flash_messages(:both)
    assert_no_match /error/, flash_messages(:both)
    flash[:error] = 'taio'
    assert_match /notice.*yoba/, flash_messages(:both)
    assert_match /error.*taio/, flash_messages(:both)
    flash[:notice] = nil
    assert_no_match /notice/, flash_messages(:both)
    assert_match /error/, flash_messages(:both)
  end
  
  def test_logo
    assert_match /logo.*img\/logo.png.*logo_msg/, logo
    assert_match /logo.*img\/logo.png.*logo_msg.*yoba/, logo('yoba')
    assert_match /logo.*img\/logo.png.*logo_msg.*Friday.*November/, logo(Time.gm(2006,11,10))
    visitor.lang = 'fr'
    assert_match /logo.*img\/logo.png.*logo_msg.*vendredi.*novembre/, logo(Time.gm(2006,11,10))
  end
  
  def test_data_url
    obj = secure(Node) { nodes(:water_pdf) }
    hash = {:controller=>'document', :action=>'data', :version_id=>obj.v_id, :filename=>obj.c_filename, :ext=>obj.c_ext}
    assert_equal hash, data_url(obj)
    obj = secure(Node) { nodes(:projects) }
    assert_raise(StandardError) { data_url(obj) }
  end
  
  def test_fsize
    assert_equal '29 Kb', fsize(29279)
    assert_equal '502 Kb', fsize(513877)
    assert_equal '5.2 Mb', fsize(5480809)
    assert_equal '450.1 Mb', fsize(471990272)
    assert_equal '2.35 Gb', fsize(2518908928)
  end
  # zazen is tested in zazen_test.rb
  
  def test_render_to_string
    assert_match 'stupid test 25', render_to_string(:inline=>'stupid <%= "test" %> <%= 5*5 %>')
  end
  
  def test_menu
    menus = nil
    assert_nothing_raised { menus = show_menu }
    assert_no_match %r{bananas}, menus
    login(:tiger)
    assert_match %r{bananas}, show_menu
  end
  
  def test_calendar_has_note
    op_at = nodes(:opening).log_at
    zena = secure(Node) { nodes(:zena) }
    cal = calendar(:from=>zena, :find=>:news, :date=>Date.civil(op_at.year, op_at.month, 5), :size=>:tiny)
    assert_match %r{class='sun'><p>12}, cal
    assert_match %r{<b class='has_note'>15}, cal
    cal = calendar(:from=>zena, :find=>:news, :date=>Date.civil(op_at.year, op_at.month, 5), :size=>:large)
    assert_match %r{<p>15.*onclick=.*Updater.*largecal_preview.*/z/calendar/list/.*(selected=17.*|2006-03-15.*)(selected=17.*|2006-03-15.*)</div></p>}m, cal
  end
  
  def test_calendar_today
    zena = secure(Node) { nodes(:zena) }
    cal = calendar(:from=>zena, :find=>:news, :size=>:large)
    assert_match %r{<td[^>*]id='large_today'><p>#{Date.today.day}</p></td>}, cal
    cal = calendar(:from=>zena, :find=>:news, :size=>:tiny)
    assert_match %r{<td[^>*]id='tiny_today'><p>#{Date.today.day}</p></td>}, cal
  end
  
  def test_notes_list_tiny_calendar_list
    login(:tiger)
    proj = secure(Node) { nodes(:cleanWater) }
    note = secure(Note) { Note.create(:parent_id=>nodes_id(:cleanWater), :v_title=>'hello')}
    list = notes(:from=>proj, :find=>:news)
    assert_equal 1, list.size
    assert_equal 'opening', list[0].name
  end
  
  def test_notes_list_from_project
    login(:tiger)
    proj = secure(Node) { nodes(:cleanWater) }
    note = secure(Note) { Note.create(:parent_id=>nodes_id(:cleanWater), :v_title=>'hello')}
    list = notes(:from=>proj, :find=>:notes)
    assert_equal 2, list.size
    assert_equal 'opening', list[0].name
    assert_equal 'hello', list[1].name
  end
  
  # ------ these tests were in main helper ----

  def test_check_lang_same
    session[:lang] = 'en'
    obj = secure(Node) { nodes(:zena) }
    assert_equal 'en', obj.v_lang
    assert_no_match /\[en\]/, check_lang(obj)
  end
  
  def test_check_other_lang
    session[:lang] = 'io'
    obj = secure(Node) { nodes(:zena) }
    assert_match /\[en\]/, check_lang(obj)
  end
  
  def test_change_lang
    assert_equal ({:overwrite_params=>{:prefix=>'io'}}), change_lang('io')
    login(:ant)
    assert_equal ({:overwrite_params=>{:lang=>'io'}}), change_lang('io')
  end
  
  def test_title_partial
    @node = secure(Node) { nodes(:tiger) }
    assert_equal 'contact/title', title_partial
    @node = secure(Node) { nodes(:tracker) }
    assert_equal 'main/title', title_partial
    @node = secure(Node) { nodes(:bird_jpg)}
    assert_equal 'document/title', title_partial
  end
  
  def test_node_actions_for_public
    @node = secure(Node) { nodes(:cleanWater) }
    assert !@node.can_edit?, "Node cannot be edited by the public"
    res = node_actions(:actions=>:all)
    assert_equal '', res
  end
  
  def test_node_actions_wiki_public
    @node = secure(Node) { nodes(:wiki) } 
    assert @node.can_edit?, "Node can be edited by the public"
    res = node_actions(:actions=>:all)
    assert_match %r{/z/version/edit/19}, res
    assert_match %r{/z/node/drive\?.*version_id=19}, res
  end
  
  def test_node_actions_for_ant
    login(:ant)
    @node = secure(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_match    %r{/z/version/edit}, res
    assert_no_match %r{/z/node/drive}, res
  end
  
  def test_node_actions_for_tiger
    login(:tiger)
    @node = secure(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_match %r{/z/version/edit}, res
    assert_match %r{/z/node/drive}, res
    @node.edit!
    res = node_actions(:actions=>:all)
    assert_match %r{/z/version/edit}, res
    assert_match %r{/z/version/propose}, res
    assert_match %r{/z/version/publish}, res
    assert_match %r{/z/node/drive}, res
    @node.save
    login(:ant)
    session[:lang] = 'fr'
    @node = secure(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_match %r{/z/version/edit}, res
    assert_no_match %r{/z/node/drive}, res
    session[:lang] = 'en'
    @node = secure(Node) { Node.find(nodes_id(:cleanWater)) }
    res = node_actions(:actions=>:all)
    assert_no_match %r{/z/version/edit}, res
    assert_no_match %r{/z/node/drive}, res
  end
  
  def test_traductions
    session[:lang] = 'en'
    # we must initialize an url for url_rewriting in 'traductions'
    @controller.instance_eval { @url = ActionController::UrlRewriter.new( @request, {:controller=>'nodes', :action=>'index'} ) }
    @node = secure(Node) { Node.find(nodes_id(:status)) } # en,fr
    trad = traductions
    assert_equal 2, trad.size
    assert_match /class='on'.*href="\/en"/, trad[0]
    assert_no_match /class='on'/, trad[1]
    @node = secure(Node) { Node.find(nodes_id(:cleanWater)) } #  en
    trad = traductions
    assert_equal 1, trad.size
    session[:lang] = 'io'
    trad = traductions
    assert_equal 2, trad.size
    assert_match /class='off'/, trad[1]
  end
  
  def test_show_path_root
    @node = secure(Node) { Node.find(nodes_id(:zena))}
    assert_equal "<ul class='path'><li><a href='/en' class='current'>zena</a></li></ul>", show_path
    node2 = @node
    @node = secure(Node) { Node.find(nodes_id(:status))}
    assert_match %r{ul class='path'.*zena.*projects.*cleanWater.*li.*page22\.html' class='current'>status}m, show_path(node2)
  end
  
  def test_show_path_root_with_login
    login(:ant)
    @node = secure(Node) { Node.find(nodes_id(:zena))}
    assert_equal "<ul class='path'><li><a href='/#{AUTHENTICATED_PREFIX}' class='current'>zena</a></li></ul>", show_path
  end
  
  def test_admin_link_translation
    assert_equal '', show_link(:translation)
    login(:lion)
    assert_match %r{Translate interface.*z/trans/list.*\?translate=on}, show_link(:translation)
    session[:translate] = true
    assert_match %r{Translate interface.*z/trans/list.*\?translate=off}, show_link(:translation)
  end

  def test_lang_links
    login(:lion)
    @request = ActionController::TestRequest.new
    @request.instance_eval{ @parameters = {:controller=>'nodes', :action=>'show', :path=>'projects/cleanWater', :prefix=>AUTHENTICATED_PREFIX}}
    class << self
      def request
        @request
      end
    end
    assert_match %r{id='lang'.*span.*b.*en.*href=.*/oo/projects/cleanWater\?lang=es.*es.*fr.*}, lang_links
    session[:translate] = true
    assert_match %r{id='lang'.*span.*b.*en.*href=.*/oo/projects/cleanWater\?lang=es.*es.*fr.*z/trans/list.*translate=off}, lang_links
    class << self
      remove_method(:request)
    end
    remove_instance_variable :@request
  end
  
  def test_lang_links_no_login
    @request = ActionController::TestRequest.new
    @request.instance_eval{ @parameters = {:controller=>'nodes', :action=>'show', :path=>'projects/cleanWater', :prefix=>AUTHENTICATED_PREFIX}}
    class << self
      def request
        @request
      end
    end
    assert_match %r{id='lang'.*span.*b.*en.*href=.*/es/projects/cleanWater.*es.*/fr/projects/cleanWater.*fr.*}, lang_links
    class << self
      remove_method(:request)
    end
    remove_instance_variable :@request
  end
  
  def test_lang_ajax_link
    login(:lion)
    assert_match %r{<div id='lang'><span>.*new Ajax.Update.*/z/trans/lang_menu}, lang_ajax_link
    session[:translate] = true
    assert_match %r{<div id='lang'><span>.*new Ajax.Update.*/z/trans/lang_menu.*translate=off}, lang_ajax_link
  end
  
  def rescue_action(e)
    puts "ERROR"
    raise
  end
end
