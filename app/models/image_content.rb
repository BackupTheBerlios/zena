class ImageContent < DocumentContent
  
  def file=(aFile)
    super
    remove_format_images if !new_record?
    return unless ImageBuilder.image_content_type?(aFile.content_type)
    img = image_for_format(nil)
    self[:width ] = img.width
    self[:height] = img.height
  end
  
  def img_tag(format=nil, opts={})
    options = {:class=>(format || 'full'), :id=>nil, :alt=>name}.merge(opts)
    format = verify_format(format)
    if format && self[:width] && self[:height]
      # build image tag
      img = image_for_format(format)
      "<img src='/data#{path(format)}' width='#{img.width}' height='#{img.height}' alt='#{options[:alt]}' #{options[:id] ? "id='#{options[:id]}' " : ""}class='#{options[:class]}'/>"
    elsif format
      # cannot build if 'width' and 'height' are not set
      "<img src='/data#{path(format)}' alt='#{options[:alt]}' #{options[:id] ? "id='#{options[:id]}' " : ""}class='#{options[:class]}'/>"
    else
      # full size (format = nil)
      "<img src='/data#{path}' width='#{self.width}' height='#{self.height}' alt='#{options[:alt]}' #{options[:id] ? "id='#{options[:id]}' " : ""}class='#{options[:class]}'/>"
    end
  end
  
  def size(format=nil)
    format = verify_format(format)
    if format
      if File.exist?(filepath(format)) || make_image(format)
        File.stat(filepath(format)).size
      else
        nil
      end
    else
      super
    end
  end
  
  def width(format=nil)
    format = verify_format(format)
    if format
      if img = image_for_format(format)
        img.width
      else
        nil
      end
    else
      self[:width]
    end
  end
  
  def height(format=nil)
    format = verify_format(format)
    if format
      if img = image_for_format(format)
        img.height
      else
        nil
      end
    else
      self[:height]
    end
  end

  def filename(format=nil)
    format = verify_format(format)
    if format
      "#{name}-#{format}.#{ext}"
    else
      super(nil)
    end
  end
  
  # Send a file with the data for the given format. It is the receiver's responsability to close the file.
  def file(format=nil)
    format = verify_format(format)
    if format
      if File.exist?(filepath(format)) || make_image(format)
        File.new(filepath(format))
      else
        nil
      end
    elsif @file
      @file
    elsif File.exist?(filepath)
      File.new(filepath)
    else
      nil
    end
  end
  
  # Used to remove specific formatted images when these images are cached in the public directory
  def remove_image(format)
    return false unless format = verify_format(format)
    FileUtils::rm(filepath(format)) if File.exist?(filepath(format))
    version.node.sweep_cache
  end
  
  # Removes all images created by ImageBuilder for this image_content. This is used when the file changes.
  def remove_format_images
    dir = File.dirname(filepath)
    if File.exist?(dir)
      Dir.foreach(dir) do |file|
        next if file =~ /^\./
        next if file == filename
        FileUtils::rm(File.join(dir,file))
      end
    end
    # Remove cached images from the public directory.
    # TODO: test
    FileUtils::rmtree(File.dirname(cachepath))
  end
  
  private
  
  def valid_file
    return false unless super
    if @file && !ImageBuilder.image_content_type?(@file.content_type)
      errors.add('file', 'must be an image')
      return false
    else
      return true
    end
  end
  
  def image_for_format(format=nil)
    if @file
      ImageBuilder.new(:file=>@file).transform!(format)
    elsif !new_record?
      @formats ||= {}
      @formats[format] ||= ImageBuilder.new(:path=>filepath, 
              :width=>self[:width], :height=>self[:height]).transform!(format)
    else
      raise StandardError, "No image to work on"
    end
  end
  
  def make_image(format)
    return nil unless format && (img = image_for_format(format))
    return nil if img.dummy?
    make_file(filepath(format),img)
  end
  
  def verify_format(format)
    if format == 'full' || format.nil?
      nil
    elsif format =~ /^[a-z0-9]{1,16}$/
      format
    else
      'std'
    end
  end
end