# frozen_string_literal: true

class AddNotesLengthConfigToUtilities < ActiveRecord::Migration[5.2]
  def change
    add_column :utilities, :notes_short_limit, :integer
    add_column :utilities, :notes_medium_limit, :integer
  end
end
