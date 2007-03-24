=begin rdoc
=end
class Tag < Page
  link :tag_for, :class_name=>'Node', :as=>'tag', :collector=>true
  
  # ====== all this needs refactoring ========= #
  
  def pages(opts={})
    return super if opts[:in]
    options = opts.merge(:conditions=>"kpath NOT LIKE 'NPD%'", :or=>["parent_id = ?", self[:id]])
    @pages ||= tag_for(options)
  end
  
  def documents(opts={})
    return super if opts[:in]
    options = opts.merge(:conditions=>"kpath LIKE 'NPD%'", :or=>["parent_id = ?", self[:id]])
    @documents ||= tag_for(options)
  end
  
  # Find documents without images
  # TODO: test
  def documents_only(opts={})
    return super if opts[:in]
    options = opts.merge(:conditions=>"kpath LIKE 'NPD%' AND NOT LIKE 'NPDI%'", :or=>["parent_id = ?", self[:id]])
    @doconly ||= tag_for(options)
  end
  
  # Find only images
  # TODO: test
  def images(opts={})
    return super if opts[:in]
    options = opts.merge(:conditions=>"kpath LIKE 'NPDI%'", :or=>["parent_id = ?", self[:id]])
    @images ||= tag_for(options)
  end
end