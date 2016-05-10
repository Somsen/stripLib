class CampaignsController < ApplicationController
  
  STAMPED      = 0 # 0 .. TOTAL_STAMPS

  # strip 
  STRIP_WIDTH  = 640
  STRIP_HEIGHT = 246
  STRIP_NAME   = "strip.png"

  # stamp
  STAMP_WIDTH  = 90
  STAMP_HEIGHT = 90
  STAMP_NAME   = "stamp.png"

  # unstamp
  UNSTAMP_NAME = "unstamp.png"

  MIN_NUMBER_STAMPS = 6
  NUMBER_ITERATIONS = 3

  def index
    @campaigns = Campaign.all
  end

  def new
    @campaign = Campaign.new
  end

  def create
    ActiveRecord::Base.transaction do

      @campaign = Campaign.new
      @campaign.images.new(images_params[:strip]).save
      @campaign.images.new(images_params[:stamp]).save
      @campaign.images.new(images_params[:unstamp]).save

      strip = create_punch_card(@campaign.images.first.file.path, @campaign.images.second.file.path, @campaign.images.last.file.path, 4, 8)
      @campaign.images.new(image_type: :background, file: File.open(strip.path)).save

      @campaign.save

      return redirect_to action: :index
    end

    return render :new
  end

  def destroy
    @campaign = Campaign.find(params[:id])
    @campaign.destroy
    return redirect_to campaigns_path
  end

  def crop_image
    @strip.crop_image
  end

  def create_punch_card(strip_image_name, stamp_image_name, unstamp_image_name, number_stamps, total_stamps)
    # load strip image
    strip_resize_value = resize_value(STRIP_WIDTH, STRIP_HEIGHT)
    strip_image        = load_image(strip_image_name, strip_resize_value)

    #load stamp image
    stamp_resize_value = resize_value(STAMP_WIDTH, STAMP_HEIGHT)
    stamp_image        = load_image(stamp_image_name, stamp_resize_value)

    #load unstamp; create if no file found
    if !File.exists?(unstamp_image_name)
      create_unstamp_image(stamp_image_name, 50, unstamp_image_name)
    end
    unstamp_image = load_image(unstamp_image_name, stamp_resize_value)

    
    # ADD STAMPS
    for i in 0..number_stamps-1
      strip_image = composite_image(strip_image, stamp_image, i, total_stamps)
    end

    # ADD UNSTAMPED
    for i in number_stamps..total_stamps-1
      strip_image = composite_image(strip_image, unstamp_image, i, total_stamps)
    end

    strip_image

  end

  def resize_value(width, height)
    "#{width}x#{height}"
  end

  def load_image(filename, resize_value)
    # get image and resize
    image = MiniMagick::Image.open(filename)
    image.resize resize_value

    image
  end

  def create_unstamp_image(stamp_image, opacity, output)
    MiniMagick::Tool::Convert.new do |convert|
      convert << stamp_image
      convert.merge! ["-alpha", "set", "-channel", "A", "-evaluate", "set", "#{opacity}%"]
      convert << output
    end
  end

  def composite_image(strip_image, stamp_image, current_stamp, total_stamps)
    (x,y) = get_coordinates(current_stamp, total_stamps)

    strip_image = strip_image.composite(stamp_image) do |c|
      c.compose "Over"
      c.geometry "+#{x}+#{y}"
    end  

    strip_image
  end


  def get_coordinates(current_stamp, total_stamps)
    # X coordinate
    stamps_per_row    = total_stamps/2
    x_stamp_space     = stamps_per_row * STAMP_WIDTH
    x_left_over_space = STRIP_WIDTH - x_stamp_space
    x_gap             = x_left_over_space / (stamps_per_row + 1)

    pos_x             = x_gap + (current_stamp % stamps_per_row) * (STAMP_WIDTH + x_gap)
    
    # Y coordinate
    stamps_per_column = 2
    y_stamp_space     = stamps_per_column * STAMP_HEIGHT
    y_left_over_pace  = STRIP_HEIGHT - y_stamp_space
    y_gap             = y_left_over_pace / (stamps_per_column + 1)

    pos_y             = y_gap + (current_stamp / stamps_per_row) * (STAMP_HEIGHT + y_gap)

    [pos_x, pos_y]

  end

  private
    def strip_params
      allow = %w(file file_cache crop_x crop_y width height)
      params.require(:strip).permit(allow)#.merge(image_type: :strip)
    end

    def stamp_params
      allow = %w(file file_cache crop_x crop_y width height)
      params.require(:strip).permit(allow)#.merge(image_type: :stamp)
    end

    def unstamp_params
      allow = %w(file file_cache crop_x crop_y width height)
      params.require(:strip).permit(allow)#.merge(image_type: :unstamp)
    end

    def images_params
      image_allow = %w(file file_cache image_type crop_x crop_y width height)

      params.require(:campaign).permit(strip: image_allow , stamp: image_allow, unstamp: image_allow)
    end
end
