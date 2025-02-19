class CommentsController < ApplicationController
    before_action :set_post
    before_action :set_comment, only: [:edit, :update, :destroy]
  
    def edit
    end

    def create
        @comment = @post.comments.build(comment_params)
        if @comment.save
            redirect_to @post, notice: 'Comment added successfully.'
        else
            redirect_to @post, alert: 'Comment cannot be empty.'
        end
    end

    def update
        if @comment.update(comment_params)
            redirect_to @post, notice: 'Comment was successfully updated.'
        else
            render :edit
        end
    end
  
    def destroy
        @comment = @post.comments.find(params[:id])
        @comment.destroy
        redirect_to @post, notice: 'Comment was successfully deleted.'
    end
    
    private
  
    def set_post
        @post = Post.find(params[:post_id])
    end

    def set_comment
        @comment = @post.comments.find(params[:id])
    end
  
    def comment_params
        params.require(:comment).permit(:content)
    end
end
  