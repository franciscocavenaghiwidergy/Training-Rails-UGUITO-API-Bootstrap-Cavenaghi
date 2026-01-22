require 'rails_helper'

RSpec.describe Note, type: :model do
  let(:utility) { create(:north_utility) }

  let(:user) { create(:user, utility: utility) }

  subject(:note) { build(:note, user: user, note_type: :review) }

  it 'belongs to a user' do
  association = described_class.reflect_on_association(:user)
  expect(association.macro).to eq(:belongs_to)
  end

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }

  it 'has a valid factory' do
    expect(note).to be_valid
  end

  context 'when user belongs to NorthUtility' do
    let(:utility) { create(:north_utility) }

    it 'is invalid when review content exceeds 50 words' do
      note.content = Faker::Lorem.words(number: 51).join(' ')

      expect(note).not_to be_valid
      expect(note.errors[:content]).to be_present
    end

    it 'is valid when review content is exactly 50 words' do
      note.content = Faker::Lorem.words(number: 50).join(' ')

      expect(note).to be_valid
    end
  end

  context 'when user belongs to SouthUtility' do
    let(:utility) { create(:south_utility) }

    it 'is invalid when review content exceeds 60 words' do
      note.content = Faker::Lorem.words(number: 61).join(' ')

      expect(note).not_to be_valid
      expect(note.errors[:content]).to be_present
    end

    it 'is valid when review content is exactly 60 words' do
      note.content = Faker::Lorem.words(number: 60).join(' ')

      expect(note).to be_valid
    end
  end

  context 'when note is not a review' do
    let(:utility) { create(:north_utility) }

    it 'does not apply word limit validation' do
      note.note_type = :critique
      note.content = Faker::Lorem.words(number: 200).join(' ')

      expect(note).to be_valid
    end
  end
end
