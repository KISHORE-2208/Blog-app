class PostsController < ApplicationController
    before_action :set_post, only: %i[show edit update destroy]
  
    def index
        @posts = Post.all
    end
  
    def show
        @posts = Post.all
    end
  
    def new
        @post = Post.new
    end
  
    def create
        @post = Post.new(post_params)
        if @post.save
          @post.image.attach(params[:post][:image]) if params[:post][:image].present?
          redirect_to @post, notice: "Post was successfully created."
        else
          render :new
        end
      end      
    end
      
      
  
    def edit
    end
  
    def update
        if @post.update(post_params)
            redirect_to @post, notice: 'Post was successfully updated.'
        else
            render :edit
        end
    end
  
    def destroy
        @post.destroy
        redirect_to posts_url, notice: 'Post was successfully deleted.'
    end

    def upload_image
        @post = Post.find(params[:id])
    end
      
    def save_image
        @post = Post.find(params[:id])
        if params[:post][:image].present?
            @post.image.attach(params[:post][:image])
            flash[:notice] = "Image uploaded successfully!"
        else
            flash[:alert] = "Please select an image."
        end
        redirect_to @post
    end
    
    private
    def post_params
        params.require(:post).permit(:title, :content, :image)
    end

    def set_post
        @post = Post.find(params[:id])
    end
    
end
  