require 'rails_helper'

RSpec.describe Note, type: :model do
  let(:utility) { create(:north_utility) }
  let(:user) { create(:user, utility: utility) }

  subject(:note) { build(:note, user: user, note_type: :review) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to belong_to(:user) }

  RSpec.shared_examples 'review word limit validation' do |factory, limit|
    let(:utility) { create(factory) }

    it "is invalid when review content exceeds #{limit} words" do
      note.content = Faker::Lorem.words(number: limit + 1).join(' ')

      expect(note).not_to be_valid
      expect(note.errors[:content]).to be_present
    end

    it "is valid when review content is exactly #{limit} words" do
      note.content = Faker::Lorem.words(number: limit).join(' ')

      expect(note).to be_valid
    end
  end

  context 'when user belongs to NorthUtility' do
    it_behaves_like 'review word limit validation', :north_utility, 50
  end

  context 'when user belongs to SouthUtility' do
    it_behaves_like 'review word limit validation', :south_utility, 60
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
