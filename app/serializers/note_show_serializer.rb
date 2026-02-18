class NoteShowSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :type,
             :word_count,
             :created_at,
             :content,
             :content_length

  belongs_to :user, serializer: UserSerializer

  def type
    object.note_type
  end

  def word_count
    object.word_count
  end

  def content_length
    object.content_length
  end
end