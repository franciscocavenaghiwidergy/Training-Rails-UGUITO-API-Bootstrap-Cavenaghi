# == Schema Information
#
# Table name: notes
#
#  id         :bigint(8)        not null, primary key
#  title      :string
#  content    :text
#  note_type  :string
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Note < ApplicationRecord
  belongs_to :user

  NOTE_TYPES = %w[review critique].freeze

  validates :title, presence: true
  validates :content, presence: true
  validates :note_type, presence: true, inclusion: { in: NOTE_TYPES }
end
