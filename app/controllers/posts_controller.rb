require 'openai'
require 'json'

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
      if params[:post][:image].present?
        @post.image.attach(params[:post][:image])
      end

      # Ensure image is attached and retrieve Cloudinary URL
      if @post.image.attached?
        image_url = Rails.application.routes.url_helpers.rails_blob_url(@post.image, only_path: false)
        Rails.logger.info "Generated Image URL: #{image_url}" # Debugging

        chatgpt_response = evaluate_homework(image_url)
        @post.update(evaluation_response: chatgpt_response)
      end

      redirect_to @post, notice: "Post was successfully created."
    else
      Rails.logger.error "Post creation failed: #{@post.errors.full_messages.join(', ')}"
      render :new
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

  def evaluate_homework(image_url)
    prompt = "Please provide your evaluation for each question based on the Answer Key provided to you. The answer can be similar, not necessarily exact. Reference the Question ID in your response and follow the response format. If any answer is incorrect, reverify your response and give the output."

    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    parameters = {
      model: "gpt-4-vision-preview",
      messages: [{ role: "user", content: [
        { "type": "text", "text": prompt },
        { "type": "image_url", "image_url": { "url": image_url } }
      ]}],
      response_format: {
        "type": "json_schema",
        "json_schema": {
          "name": "homework",
          "schema": {
            "type": "object",
            "properties": {
              "responses": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "question": {"type": "string"},
                    "question_id": {"type": "string"},
                    "student_answer": {"type": "string"},
                    "correct": {"type": "boolean"},
                    "explanation": {"type": "string"}
                  },
                  "required": ["question", "question_id","student_answer","correct","explanation"],
                  "additionalProperties": false
                }
              }
            },
            "required": ["responses"],
            "additionalProperties": false
          },
          "strict": true
        }
      }
    }

    begin
      response = client.chat(parameters: parameters)
      chatgpt_response = response.dig("choices", 0, "message", "content")
      JSON.parse(chatgpt_response) # Ensure it's valid JSON
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed: #{e.message}"
      { error: "Failed to parse response" }
    rescue => e
      Rails.logger.error "ChatGPT API request failed: #{e.message}"
      { error: "API request failed" }
    end
  end
end
