class CampaignsController < ApplicationController

  protect_from_forgery with: :null_session

  before_action :load_campaign_and_images, only: [:design_strip, :show]
  
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

  def show

  end

  def index
    @campaigns = Campaign.all
  end

  def new
    @campaign = Campaign.new
  end

  def edit
    @campaign = Campaign.find(params[:id])
  end

  def create
    @campaign = Campaign.new(campaign_params)
    # @campaign.images.new(image_type: :full)
    if @campaign.save
      redirect_to design_strip_campaign_path(@campaign)
    else
      render :new
    end
  end

  def update
    @campaign = Campaign.find(params[:id])

    if @campaign.update(campaign_params)
      redirect_to @campaign
    else
      render :edit
    end
  end

  def destroy
    @campaign = Campaign.find(params[:id])
    @campaign.destroy
    return redirect_to campaigns_path
  end

  def design_strip
    if @strip.nil?
      @strip = @campaign.images.build(image_type: :strip)
    end
    if @stamp.nil?
      @stamp = @campaign.images.build(image_type: :stamp)
    end
    if @unstamp.nil?
      @unstamp = @campaign.images.build(image_type: :unstamp)
    end

  end

  def design_strip_post
    
  end

  def image_upload
    @campaign = Campaign.find(params[:id])
    type     = params[:type]
    tmp = Tempfile.new("#{type}.png")
    tmp.binmode
    tmp.write Base64.decode64(params[:image]['data:image/png;base64,'.length .. -1])
    tmp.rewind
    file = ActionDispatch::Http::UploadedFile.new({
          tempfile: tmp,
          content_type: "image/png",
          filename: "#{type}.png"
        })
    
    # find current image for given type
    image = @campaign.images.find_by(image_type: Image.image_types[type]);

    # if no image found - create a new one;
    # else - update current image file
    if image.nil?
      image = @campaign.images.create(file: file, image_type: type)
    else
      image.update(file: file);
    end

    # generate the preview strip
    generate_preview_strip false

    # json_response = @campaign.images.inject({}) do |hash, image|
    #   hash["#{image.image_type}"] = {
    #     "#{image.image_type}_url": "#{image.file.url}?#{image.updated_at.to_i}",
    #     "#{image.image_type}_id": image.id
    #   }
    #   # hash["#{image.image_type}_url"] = "#{image.file.url}?#{image.updated_at.to_i}"
    #   # hash["#{image.image_type}_id"]  = image.id
    #   hash
    # end

    return render json: json_response

    # return render json: {
    #   image_id: image.id,
    #   image_url: "#{image.file.url}?#{image.updated_at.to_i}",
    #   full_strip: "#{@campaign.images.full.first.file.url}?#{@campaign.images.full.first.updated_at}"
    # }
  end

  def change_stamps
    @campaign = Campaign.find(params[:id])
    number_stamps = params[:stamps]

    if @campaign.stamp_number != number_stamps

      if @campaign.update(stamp_number: number_stamps)
      
        full_strip = @campaign.images.full.first

        if !full_strip.nil?
          # store_dir = full_strip.file.store_dir
          # file_path = "public/#{store_dir}/full#{number_stamps}.png"
          # if File.exists?(file_path)
          #   cache_file_full_strip = File.open(file_path)
          #   if store_dir.update(file: cache_file_full_strip)
          #     return render json: json_response
          #   else
          #     # UNABLE TO UPDATE IMAGE
          #   end
          # else
          #   generate_preview_strip(false)
          #   return render json: json_response
          # end
          generate_preview_strip(false)
          return render json: json_response

        end # end !full_strip.nil?
      end # end @campaign.update(stamp_number: number_stamps)
    end # end @campaign.stamp_number != number_stamps

    return render json: { ok: "OK!" }
  end

  def destroy_strip
    image_destroy("strip")
  end

  def destroy_stamp
    image_destroy("stamp")
  end

  def destroy_unstamp
    image_destroy("unstamp")
  end

  def image_destroy(type)
    @campaign = Campaign.find(params[:id])
    # type     = params[:type]

    image = @campaign.images.find_by(image_type: Image.image_types[type]);
    if !image.nil?
      if image.destroy
        if generate_preview_strip true
          return render json: {remove_full: true}
        end
        return render json: json_response
      else
        return render json: { errors: "Couldn't remove image image!" } 
      end
    end
  end

  protected

  def json_response
    json = @campaign.images.inject({}) do |hash, image|
      hash["#{image.image_type}"] = {
        "#{image.image_type}_url": "#{image.file.url}?#{image.updated_at.to_i}",
        "#{image.image_type}_id": image.id
      }
      # hash["#{image.image_type}_url"] = "#{image.file.url}?#{image.updated_at.to_i}"
      # hash["#{image.image_type}_id"]  = image.id
      hash
    end

    json
  end

  def create_default_strip
    MiniMagick::Tool::Convert.new do |convert|
      convert.merge! ["-size", "640x248", "xc:transparent", "write.png"]
    end
    teste = MiniMagick::Image.open("write.png");

    file = ActionDispatch::Http::UploadedFile.new({
          tempfile: teste,
          content_type: "image/png",
          filename: "strip.png"
        })
    @campaign.images.create(file: file, image_type: :strip)
  end

  def create_unstamp_image(stamp_image, opacity)
    MiniMagick::Tool::Convert.new do |convert|
      convert << stamp_image
      convert.merge! ["-alpha", "on", "-channel", "A", "+level", "0,#{100-opacity}%"]
      convert << "unstamp.png"
    end

    teste = MiniMagick::Image.open("unstamp.png");

    file = ActionDispatch::Http::UploadedFile.new({
          tempfile: teste,
          content_type: "image/png",
          filename: "unstamp.png"
        })
    @campaign.images.create(file: file, image_type: :unstamp)

  end

  def generate_preview_strip(from_delete)
    strip         = @campaign.images.strip.first
    stamp         = @campaign.images.stamp.first
    unstamp       = @campaign.images.unstamp.first
    preview_strip = @campaign.images.full.first
    total_stamps  = @campaign.stamp_number
    number_stamps = total_stamps / 2
 
    # generate a default strip if there is no strip
    if strip.nil?
      # if !stamp.nil? || !unstamp.nil?
      #   strip = create_default_strip
      # elsif !preview_strip.nil?
      if stamp.nil? && unstamp.nil? && !preview_strip.nil?
        # destroy preview strip because the is nothing to preview
        preview_strip.destroy
        return true
      end
    end

    # load final strip preview
    MiniMagick::Tool::Convert.new do |convert|
      convert.merge! ["-size", "640x248", "xc:transparent", "write.png"]
    end

    transparent_strip = MiniMagick::Image.open("write.png")

    # add stamps to final strip preview
    if !stamp.nil?
      stamp_image = MiniMagick::Image.open(stamp.file.path)
      # ADD STAMPS
      for i in 0..number_stamps-1
        transparent_strip = composite_image(transparent_strip, stamp_image, i, total_stamps)
      end
    end

    # add unstamps to final strip preview
    if unstamp.nil? && !stamp.nil? && !from_delete
        unstamp = create_unstamp_image(stamp.file.path, 50)
    end

    if !unstamp.nil?
      unstamp_image = MiniMagick::Image.open(unstamp.file.path)
      # ADD UNSTAMPED
      for i in number_stamps..total_stamps-1
        transparent_strip = composite_image(transparent_strip, unstamp_image, i, total_stamps)
      end
    end

    # put unstamps over stamp
    if !strip.nil?
      final_strip_preview = MiniMagick::Image.open(strip.file.path)
      final_strip_preview = compose_strip_with_stamps(final_strip_preview, transparent_strip)
    else
      final_strip_preview = transparent_strip
    end
    # save the generated preview strip
    file          = ActionDispatch::Http::UploadedFile.new({
                    tempfile: final_strip_preview,
                    content_type: "image/png",
                    filename: "full#{total_stamps}.png"
                  })

    if preview_strip.nil?
      # create camaign preview strip
      @campaign.images.create(file: file, image_type: :full)
    else
      # update campaign preview strip
      preview_strip.update(file: file)
    end

    return false
  end

  def composite_image(final_strip_image, stamp_image, current_stamp, total_stamps)
    (x,y) = get_coordinates(current_stamp, total_stamps)

    final_strip_image = final_strip_image.composite(stamp_image) do |c|
      c.compose "Over"
      c.geometry "+#{x}+#{y}"
    end  

    final_strip_image
  end

  def compose_strip_with_stamps(final_strip_image, stamps_image)
    final_strip_image = final_strip_image.composite(stamps_image) do |c|
      c.compose "Over"
    end  

    final_strip_image
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

    def load_campaign_and_images
      @campaign   = Campaign.find(params[:id])
      @strip      = @campaign.images.strip.first
      @stamp      = @campaign.images.stamp.first
      @unstamp    = @campaign.images.unstamp.first
      @full_strip = @campaign.images.full.first
    end

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

    def campaign_params
      allow = %w(name stamp_number)
      params.require(:campaign).permit(allow)
      
    end
end
