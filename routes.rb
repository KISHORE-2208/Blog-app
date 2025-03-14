Rails.application.routes.draw do
  post 'preview_post', to: 'posts#preview'

  resources :posts do
    member do
      get :upload_image
      patch :save_image
    end
    resources :comments, only: [:create, :edit, :update, :destroy]
  end
  root 'posts#index'
end
