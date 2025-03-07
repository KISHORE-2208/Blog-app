class AddEvaluationResponseToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :evaluation_response, :text
  end
end
