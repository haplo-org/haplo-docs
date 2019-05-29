
require 'erb'

module DocImages
  extend ERB::Util

  IMAGE_TEMPLATE_FILENAME = 'web/image_template.html.erb'
  SIZE_MUL = 2
  SIZE_DIV = 3

  ImageSize = Struct.new(:x,:y)

  def self.image_size(filename)
    size = nil
    input = Java::JavaxImageio::ImageIO.createImageInputStream(java.io.File.new(filename));
    if input
      iter = Java::JavaxImageio::ImageIO.getImageReaders(input)
      if iter.hasNext()
          reader = iter.next()
          reader.setInput(input)
          size = ImageSize.new(reader.getWidth(0), reader.getHeight(0))
          reader.dispose();
      end
      input.close();
    end
    raise "Couldn't get image size for #{filename}" unless size
    size
  end

  @@template = nil

  def self.replace_image_markers_with_html(text, path)
    # Load template?
    @@template ||= begin
      source = File.open(IMAGE_TEMPLATE_FILENAME) { |f| f.read }
      source.gsub!(/[ \t]+[\r\n][ \r\n\t]+/,'') # remove all line endings and indents so everything goes on one line
      ERB.new(source)
    end

    text.gsub(/\[IMAGE\s+(\S+?)(\s+(.+?))?\]/) do
      image_name = $1
      caption = $3
      disk_dir = "images#{path}"
      disk_pathname = "#{disk_dir}/#{image_name}"
      image_exists = File.exist?(disk_pathname)
      web_path = "/images#{path}/#{image_name}"
      if image_exists
        size = image_size(disk_pathname)
        scaled_x = (size.x * SIZE_MUL) / SIZE_DIV
        scaled_y = (size.y * SIZE_MUL) / SIZE_DIV
      else
        unless DocServer.running?
          raise "Image doesn't exist: #{disk_pathname}"
        end
        FileUtils.mkdir_p disk_dir
      end
      @@template.result(binding)
    end
  end

end