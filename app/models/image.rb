class Image < ActiveRecord::Base

  mount_uploader :file, ImageUploader

  enum image_type: [:strip, :background, :stamp, :unstamp, :full]
  
  belongs_to :campaign

  attr_accessor :crop_x, :crop_y, :width, :height

  before_save :reprocess_image

  validates :image_type, presence: true

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !width.blank? && !height.blank?
  end

  def ratio
    if file.path.nil?
      1
    else
      image = MiniMagick::Image.open(file.path)
      image.width / @width
    end
  end

  def reprocess_image
    image = MiniMagick::Image.open(file.path)

    if cropping?
      image.combine_options do |i|
        i.crop "#{width}x#{height}+#{crop_x}+#{crop_y}!"
      end
    end    

    image.resize type_size
    image.write(file.path)
  end

  def crop_image
    image = MiniMagick::Image.open(file.path)

    if cropping?
      image.combine_options do |i|
        i.crop "#{width}x#{height}+#{crop_x}+#{crop_y}!"
      end
    end    
  end

  def type_size
    case image_type.to_sym
    when :strip
      "640x246\!"  # ignore aspect ratio flag '\!'
    when :background
      "640x246"
    when :stamp
      "90x90\!"
    when :unstamp
      "90x90\!"
    when :full
      "640x246"
    else
      "1x1\!"
    end
  end

end
