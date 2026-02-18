class BaseNoteSerializer < ActiveModel::Serializer
  attributes :id, :title, :type, :word_count, :created_at, :content_length

  def type
    object.note_type
  end
end
