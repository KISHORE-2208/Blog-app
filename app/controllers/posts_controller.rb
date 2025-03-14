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
    if params[:post][:image].present?
      @post.image.attach(params[:post][:image]) if params[:post][:image].present?
    end
    if @post.save
      if @post.image.attached? 
        Rails.logger.info "STARTING API"
        Rails.logger.info "Generated Image URL: #{url_for(@post.image)}"
  
        prompt = "Evaluate the student's handwritten homework for correctness and provide structured feedback."
  
        chatgpt_response = evaluate_homework("https://res.cloudinary.com/dndv7ayic/image/upload/vbrhotuh70r0jjrp1f9rfd8n5563.jpeg", prompt)
  
        if chatgpt_response[:error].nil?
          @post.update(evaluation_response: chatgpt_response.to_json)
        else
          Rails.logger.error "API error: #{chatgpt_response[:error]}"
        end
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
    params.require(:post).permit(:title, :content, :image, :image_url, :evaluation_response)
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def attach_image_if_present
    return unless params[:post][:image].present?

    @post.image.attach(params[:post][:image])
  end



  def evaluate_homework(image_url, prompt)
    return { error: "Image URL is missing" } if image_url.nil?
  
    openai_api_key = ENV["OPENAI_API_KEY"] # Fetch from environment variables
    return { error: "Missing OpenAI API key" } if openai_api_key.nil?
  
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    parameters = {
      model: "gpt-4o-2024-08-06",
      messages: [
        { role: "system", content: "You are an expert handwriting evaluator. Provide structured feedback on students' handwritten homework." },
        { role: "user", content: "#{prompt}\n\nImage: #{image_url}" }
      ],
      max_tokens: 500
    }
  
    begin
      response = client.chat(parameters: parameters)
      chatgpt_response = response.dig("choices", 0, "message", "content")
      JSON.parse(chatgpt_response) # Ensure valid JSON response
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parsing failed: #{e.message}"
      { error: "Failed to parse response" }
    rescue Faraday::UnauthorizedError => e
      Rails.logger.error "Unauthorized! Check API key: #{e.message}"
      { error: "Unauthorized API access. Check your API key." }
    rescue OpenAI::Error => e
      if e.message.include?("Rate limit")
        Rails.logger.error "OpenAI rate limit exceeded. Try again later."
        { error: "Rate limit exceeded, please wait and retry." }
      else
        Rails.logger.error "OpenAI API error: #{e.message}"
        { error: "API request failed" }
      end
    end    
  end    
end