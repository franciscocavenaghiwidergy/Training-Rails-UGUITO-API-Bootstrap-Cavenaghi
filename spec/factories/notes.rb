FactoryBot.define do
  factory :note do
    title { "MyString" }
    content { "MyText" }
    note_type { "MyString" }
    user { nil }
  end
end
