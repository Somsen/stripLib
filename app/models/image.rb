class Image < ActiveRecord::Base

  mount_uploader :file, ImageUploader

  enum image_type: [:strip, :background, :stamp, :unstamp, :full]
  
  belongs_to :campaign

  attr_accessor :crop_x, :crop_y, :width, :height

  before_save :resize_image

  validates :image_type, presence: true

  def resize_image
    case image_type.to_sym
    when :strip
      width, height = [640,246]
      file.resize_to_fill(width, height)
    when :background
      width, height = [640,246]
      file.resize_to_fill(width, height)
    when :stamp
      width, height = [90,90]
      file.resize_to_fit(width, height)
    when :unstamp
      width, height = [90,90]
      file.resize_to_fit(width, height)
    when :full
      width, height = [640,246]
      file.resize_to_fill(width, height)
    else
      width, height = [1,1]
    end
  end

end
