Rails.application.routes.draw do

  resources :images, path: 'strips'

  resources :campaigns


  root controller: :images, action: :index
  #root 'welcome#index' 
end
