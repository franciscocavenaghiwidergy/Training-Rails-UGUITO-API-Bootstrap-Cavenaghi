class ShowNoteSerializer < BaseNoteSerializer
  attributes :id, :title, :type, :word_count, :created_at, :content_length, :content

  belongs_to :user, serializer: UserSerializer
end
