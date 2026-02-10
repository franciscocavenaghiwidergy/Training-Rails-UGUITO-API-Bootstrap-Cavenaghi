class ShowNoteSerializer < ActiveModel::Serializer
  attributes :id, :title, :type, :word_count, :created_at, :content, :content_length

  belongs_to :user, serializer: NoteUserSerializer

  def type
    note_type_to_string(object.read_attribute_before_type_cast(:note_type))
  end

  def word_count
    object.word_count
  end

  def content_length
    object.content_length
  end

  private

  def note_type_to_string(raw)
    normalized = raw.to_s.strip.downcase
    return 'critique' if %w[1 critique].include?(normalized)
    return 'review' if %w[0 review].include?(normalized)

    'review'
  end
end
