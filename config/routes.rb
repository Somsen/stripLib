Rails.application.routes.draw do

  resources :images, path: 'strips'

  resources :campaigns do 
    member do

      post '/image-upload', as: 'image_upload', to: 'campaigns#image_upload'

      delete '/image/strip', as: 'image/strip', to: 'campaigns#destroy_strip'
      delete '/image/stamp', as: 'image/stamp', to: 'campaigns#destroy_stamp'
      delete '/image/unstamp', as: 'image/unstamp', to: 'campaigns#destroy_unstamp'
  
      get 'design-strip',
        to: 'campaigns#design_strip',
        as: 'design_strip'

      post 'design-strip',
        to: 'campaigns#design_strip_post',
        as: 'design_strip_post'

      post 'change-stamps',
        to: 'campaigns#change_stamps',
        as: 'change_stamps'
    end
  end




  root controller: :images, action: :index
  #root 'welcome#index' 
end
