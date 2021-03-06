# encoding: utf-8
require 'cgi'

# Avoid incompatibility with rails 'chars' version in Ruby 1.8.7
unless '1.9'.respond_to?(:force_encoding)
  String.class_eval do
    begin
      remove_method :chars
    rescue NameError
      # OK
    end
  end
end

class String
  ALLOWED_CHARS_IN_URL      = " a-zA-Z0-9_\\."
  # in filename, allow '-' because it does not represent a space
  ALLOWED_CHARS_IN_FILENAME = "#{ALLOWED_CHARS_IN_URL}\\-"
  # Everything apart from a-zA-Z0-9_.-/$ are not allowed in template paths
  ALLOWED_CHARS_IN_FILEPATH = "#{ALLOWED_CHARS_IN_FILENAME}+/$"
  TO_FILENAME_REGEXP = %r{([^ #{ALLOWED_CHARS_IN_FILENAME}]+)}n
  TO_URL_NAME_REGEXP = %r{([^ #{ALLOWED_CHARS_IN_URL}])}

  # Change a title into a valid url name
  def url_name
    gsub(TO_URL_NAME_REGEXP) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '-')
  end
  
  # Retrieve original title from an url_name
  def self.from_url_name(str)
    CGI.unescape(str.tr('-', ' '))
  end

  # Change a title into a valid filename
  def to_filename
    gsub(TO_FILENAME_REGEXP) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end
  end
  
  # Retrieve original title from filename
  def self.from_filename(str)
    CGI.unescape(str.gsub('+', '%2B'))
  end

  def url_name!
    replace(url_name)
    self
  end
  
  def to_filename!
    replace(to_filename)
    self
  end

  # return a relative path from an absolute path and a root
  def rel_path(root)
    root = root.split('/')
    path = split('/')
    i = 0
    ref  = []
    while true
      if root == []
        ref = path
        break
      elsif root[0] == path[0]
        root.shift
        path.shift
      else
        # for each root element left: '..'
        ref = root.map{'..'} + path
        break
      end
    end
    ref.join('/')
  end

  # return an absolute path from a relative path and a root
  def abs_path(root)
    root = root.split('/')
    path = split('/')
    while path[0] == '..'
      root.pop
      path.shift
    end
    (root + path).join('/')
  end

end
