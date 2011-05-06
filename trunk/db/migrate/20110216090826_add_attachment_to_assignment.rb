class AddAttachmentToAssignment < ActiveRecord::Migration
  def self.up
    add_column :assignments, :attachment_file_name, :string
    add_column :assignments, :attachment_content_type, :string
    add_column :assignments, :attachment_file_size, :integer
    add_column :assignments, :attachment_updated_at, :datetime
  end

  def self.down
    remove_column :assignments, :attachment_file_name
    remove_column :assignments, :attachment_content_type
    remove_column :assignments, :attachment_file_size
    remove_column :assignnments, :attachment_updated_at
  end
end
