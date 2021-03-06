class AddVersionToNotes < ActiveRecord::Migration
  def change
    execute("set statement_timeout = 0")
    add_column :notes, :version, :integer, :null => false, :default => 0
    add_column :note_versions, :version, :integer, :null => false, :default => 0
  end
end
