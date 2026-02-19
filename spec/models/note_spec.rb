require 'rails_helper'

RSpec.describe Note, type: :model do
  let(:utility) { create(:north_utility) }
  let(:user) { create(:user, utility: utility) }

  subject(:note) { build(:note, user: user, note_type: :review) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }

  it 'requires user' do
    note_without_user = build(:note, user: nil, note_type: :critique)
    expect(note_without_user).not_to be_valid
    expect(note_without_user.errors[:user]).to be_present
  end

  RSpec.shared_examples 'review word limit validation' do
    it 'is invalid when review content exceeds the word limit' do
      note.content = Faker::Lorem.words(number: limit + 1).join(' ')

      expect(note).not_to be_valid
      expect(note.errors[:content]).to be_present
    end

    it 'is valid when review content is exactly at the word limit' do
      note.content = Faker::Lorem.words(number: limit).join(' ')

      expect(note).to be_valid
    end
  end

  context 'when user belongs to NorthUtility' do
    let(:utility) { create(:north_utility) }
    let(:limit) { 50 }

    it_behaves_like 'review word limit validation'
  end

  context 'when user belongs to SouthUtility' do
    let(:utility) { create(:south_utility) }
    let(:limit) { 60 }

    it_behaves_like 'review word limit validation'
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
