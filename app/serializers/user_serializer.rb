class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :document_number, :first_name, :last_name
end
