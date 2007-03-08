require 'fileutils'
class DocumentContent < ActiveRecord::Base
  belongs_to            :version
  
  before_validation     :prepare_content
  validate              :valid_file
  validates_presence_of :ext
  validates_presence_of :name
  validates_presence_of :version
  before_save           :before_save_content
  before_destroy        :destroy_file

  # creates and '<img.../>' tag for the file of the document using the extension to show an icon.
  # format is ignored here. It is needed by the sub-class #ImageContent.
  def img_tag(format=nil, opts={})
    options = {:class=>'doc', :id=>nil}.merge(opts)
    ext = self[:ext]
    unless File.exist?("#{RAILS_ROOT}/public/images/ext/#{ext}.png")
      ext = 'other'
    end
    unless format
      # img_tag from extension
      "<img src='/images/ext/#{ext}.png' width='32' height='32' alt='#{ext}' #{options[:id] ? "id='#{options[:id]}' " : ""}class='#{options[:class]}'/>"
    else
      img = ImageBuilder.new(:path=>"#{RAILS_ROOT}/public/images/ext/#{ext}.png", :width=>32, :height=>32)
      img.transform!(format)
      path = "#{RAILS_ROOT}/public/images/ext/"
      filename = "#{ext}-#{format}.png"
      unless File.exist?(File.join(path,filename))
        # make new image with the format
        unless File.exist?(path)
          FileUtils::mkpath(path)
        end
        if img.dummy?
          File.cp("#{RAILS_ROOT}/public/images/ext/#{ext}.png", "#{RAILS_ROOT}/public/images/ext/#{ext}-#{format}.png")
        else
          File.open(File.join(path, filename), "wb") { |f| f.syswrite(img.read) }
        end
      end
      "<img src='/images/ext/#{filename}' width='#{img.width}' height='#{img.height}' alt='#{ext}' #{options[:id] ? "id='#{options[:id]}' " : ""}class='#{options[:class]}'/>"
    end
  end
  
  def size=(s)
    raise StandardError, "Size cannot be set. It is defined by the file size."
  end
  
  def file=(aFile)
    @file = aFile
    return unless valid_file
    self[:content_type] = @file.content_type.chomp
    if @file.kind_of?(StringIO)
      self[:size] = @file.size
    else
      self[:size] = @file.stat.size
    end
    extension = self[:ext] || @file.original_filename.split('.').last
    # is this extension valid ?
    extensions = TYPE_TO_EXT[content_type]
    if extensions
      self[:ext] = extensions.include?(extension) ? extension : extensions[0]
    else
      self[:ext] = "???"
    end
  end
  
  def file(format=nil)
    if @file
      @file
    elsif File.exist?(filepath)
      File.new(filepath)
    else
      raise IOError, "File not found"
    end
  end
  
  def size(format=nil)
    return self[:size] if self[:size]
    if !new_record? && File.exist?(filepath)
      self[:size] = File.stat(filepath).size
      self.save
    end
    self[:size]
  end
  
  def filename(format=nil)
    "#{name}.#{ext}"
  end
  
  # If this is changed, also change #Document.sweep_cache
  def path(format=nil)
    "/#{ext}/#{self[:version_id]}/#{filename(format)}"
  end
  
  # Path to store the data. The path is build with the version id so we can do the security checks when uploading data.
  def filepath(format=nil)
    raise StandardError, "version not set" unless self[:version_id]
    "#{ZENA_ENV[:data_dir]}#{path(format)}"
  end
  
  # Path for cached document in the public directory.
  # If this is changed, also change #Document.sweep_cache
  def cachepath(format=nil)
    raise StandardError, "version not set" unless self[:version_id]
    "#{RAILS_ROOT}/public/data#{path(format)}" # TODO: [site_id] change all RAILS_ROOT when used in paths...
  end
  
  private
  
  def valid_file
    return true if !new_record? || @file
    errors.add('file', "can't be blank")
    return false
  end

  def prepare_content
    self[:name] = version.node[:name]
  rescue
    self[:name] = nil
  end
  
  def before_save_content
    self[:type] = self.class.to_s # make sure the type is set in case no sub-classes are loaded.
    if @file
      # destroy old file
      destroy_file unless new_record?
      # save new file
      make_file(filepath, @file)
    elsif !new_record? && (old = DocumentContent.find(self[:id])).name != self[:name]
      # TODO: clear cache
      # clear format images
      old.remove_format_images if old.respond_to?(:remove_format_images)
      FileUtils::mv(old.filepath, filepath)
    end
  end
  
  def make_file(path, data)
    p = File.join(*path.split('/')[0..-2])
    unless File.exist?(p)
      FileUtils::mkpath(p)
    end
    File.open(path, "wb") { |f| f.syswrite(data.read) }
  end
  
  def destroy_file
    # TODO: clear cache
    old_path = DocumentContent.find(self[:id]).filepath
    folder = File.join(*old_path.split('/')[0..-2])
    if File.exist?(folder)
      FileUtils::rmtree(folder)
    end
    # TODO: set content_id of versions whose content_id was self[:version_id]
  end
end
