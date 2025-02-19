Rails.application.routes.draw do
  resources :posts do
    member do
      get :upload_image
      patch :save_image
    end
    resources :comments, only: [:create, :edit, :update, :destroy]
  end
  root 'posts#index'
end
