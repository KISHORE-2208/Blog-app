Rails.application.routes.draw do
  resources :posts do
    resources :comments, only: [:create, :edit, :update, :destroy]
  end

  root 'posts#index'
end
