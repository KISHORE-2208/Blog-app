class Post < ApplicationRecord
    has_one_attached :image
    has_many :comments, dependent: :destroy
  
    validates :title, presence: true
    validates :content, presence: true
    validates :evaluation_response, presence: false 
  end
  