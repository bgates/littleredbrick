class TrackPosition < ActiveRecord::Migration
  def self.up
    add_column :tracks, :position, :integer
    Track.all.each{|t| t.position = t.name.to_i;t.save}
    remove_column :tracks, :name
  end

  def self.down
    add_column :tracks, :name, :string
    Track.all.each{|t| t.name = t.position.to_s;t.save}
    remove_column :tracks, :position
  end
end
