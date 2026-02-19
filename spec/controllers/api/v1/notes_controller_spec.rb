require 'rails_helper'

describe Api::V1::NotesController, type: :controller do
  describe 'GET #index' do
    context 'when the user is authenticated' do
      include_context 'with authenticated user'

      let(:user_notes) { create_list(:note, 5, user: user) }

      let(:ordered_notes) do
        user_notes.sort_by(&:created_at).reverse
      end

      let(:expected) do
        ActiveModel::Serializer::CollectionSerializer.new(
          notes_expected,
          serializer: IndexNoteSerializer
        ).to_json
      end

      shared_examples 'a successful index response' do
        it 'returns the expected notes' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with status 200' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching all notes' do
        let(:notes_expected) { ordered_notes }

        before do
          user_notes
          get :index
        end

        it_behaves_like 'a successful index response'
      end

      context 'when paginating notes' do
        let(:notes_expected) { ordered_notes.first(2) }

        before do
          user_notes
          get :index, params: { page: 1, page_size: 2 }
        end

        it_behaves_like 'a successful index response'
      end

      context 'when filtering by type' do
        let!(:review_notes) { create_list(:note, 2, user: user, note_type: :review) }
        let!(:critique_notes) { create_list(:note, 2, user: user, note_type: :critique) }

        let(:notes_expected) do
          critique_notes.sort_by(&:created_at).reverse
        end

        before { get :index, params: { type: 'critique' } }

        it_behaves_like 'a successful index response'
      end

      context 'when filtering with an invalid type' do
        let(:notes_expected) { ordered_notes }

        before do
          user_notes
          get :index, params: { type: 'invalid_type' }
        end

        it_behaves_like 'a successful index response'
      end
    end

    context 'when the user is not authenticated' do
      before { get :index }

      it_behaves_like 'unauthorized'
    end
  end

  describe 'GET #show' do
    context 'when the user is authenticated' do
      include_context 'with authenticated user'

      let(:note) { create(:note, user: user) }
      let(:expected) { ShowNoteSerializer.new(note, root: false).to_json }

      shared_examples 'a not found response' do
        it 'responds with status 404' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the note exists' do
        before { get :show, params: { id: note.id } }

        it 'returns the requested note' do
          expect(response.body).to eq(expected)
        end

        it 'responds with status 200' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when the note does not exist' do
        before { get :show, params: { id: Faker::Number.number } }

        it_behaves_like 'a not found response'
      end

      context 'when the note belongs to another user' do
        let(:other_note) { create(:note) }

        before { get :show, params: { id: other_note.id } }

        it_behaves_like 'a not found response'
      end
    end

    context 'when the user is not authenticated' do
      before { get :show, params: { id: Faker::Number.number } }

      it_behaves_like 'unauthorized'
    end
  end
end
