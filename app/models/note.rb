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

  delegate :utility, to: :user

  enum note_type: {
    review: 0,
    critique: 1
  }

  validates :title, presence: true
  validates :content, presence: true

  validate :get_word_limit

  def word_count
    return 0 if content.blank?

    content.split(/\s+/).size
  end

  def content_length
    utility.content_length_for(word_count)
  end

  def get_word_limit
    return unless review?

    limit = utility.get_word_limit

    if word_count > limit
      errors.add(
        :content,
        :too_long_for_review,
        limit: limit
      )
    end
  end
end

