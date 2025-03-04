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
        puts "Post Content"
        puts @post.content
        redirect_to @post, notice: "Post was successfully created."
      else
        render :new
      end      
    end
  
    def preview
        @post = Post.new  # Ensure @post is not nil
        @preview_content = params[:content]
        
        respond_to do |format|
          format.html { render :new }
          format.json { render json: { content: @preview_content } }
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
  
    private
  
    def post_params
      params.require(:post).permit(:title, :content, :image)
    end
  
    def set_post
      @post = Post.find(params[:id])
    end
end
  