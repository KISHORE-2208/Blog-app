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
      attach_image_if_present

      if @post.image.attached?
        Rails.logger.info "STARTING API"

        image_url = get_image_url(@post)
        Rails.logger.info "Generated Image URL: #{image_url}"

        prompt = "Evaluate the student's handwritten homework for correctness and provide structured feedback."

        chatgpt_response = evaluate_homework(image_url, prompt)

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
    params.require(:post).permit(:title, :content, :image, :evaluation_response)
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def attach_image_if_present
    return unless params[:post][:image].present?

    @post.image.attach(params[:post][:image])
  end

  def get_image_url(post)
    if post.image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(post.image, only_path: false)
    else
      nil
    end
  end

  def evaluate_homework(image_url, prompt)
    return { error: "Image URL is missing" } if image_url.nil?

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    parameters = {
      model: "gpt-4-turbo",
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
