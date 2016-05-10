class ImagesController < ApplicationController

  skip_before_filter  :verify_authenticity_token

  def index
    @images = Image.all
  end

  def new
    @image = Image.new
  end

  def create
    # @image = Image.new(image_params)
    # if @image.save
    #   redirect_to images_path
    # else
    #   render action: :new
    # end

    # respond_to do |format|
    #   if remotipart_submitted?
    #     if @image.save
    #       format.js
    #     end
    #   else
    #     @image = Image.new(image_params)
    #     if @image.save
    #       format.html { redirect_to images_path }
    #     else
    #       format.html { render action: :new }
    #     end
    #   end
    # end
    if remotipart_submitted?

      respond_to do |format|
        @image = Image.new(image_params.merge(image_type: :strip))
        if @image.save
          format.js
        else
          format.html { redirect_to images_path }
        end

      end
    else
      @image = Image.new(image_params)
      if @image.save
        redirect_to images_path
      else
        render action: :new
      end
    end
  end

  def destroy
    @image = Image.find(params[:id])
    @image.destroy
    return redirect_to images_path
  end

  private
    def image_params
      allow = %w(file file_cache image_type crop_x crop_y width height)
      params.require(:image).permit(allow)
    end

end
