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

  describe 'POST #create' do
    let(:valid_note_params) { { note: note_request_attributes } }

    def note_request_attributes
      attrs = attributes_for(:note)
      { title: attrs[:title], content: attrs[:content], type: attrs[:note_type].to_s }
    end

    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      before { request.headers['Utility-ID'] = user.utility.code }

      context 'when creating a note with valid params (happy path)' do
        before { post :create, params: valid_note_params }

        it 'responds with 201 status' do
          expect(response).to have_http_status(:created)
        end

        it 'responds with the created note id' do
          expect(response_body['id']).to be_present
        end

        it 'responds with the created note title' do
          expect(response_body['title']).to eq(valid_note_params[:note][:title])
        end

        it 'responds with the created note content' do
          expect(response_body['content']).to eq(valid_note_params[:note][:content])
        end

        it 'responds with the created note type' do
          expect(response_body['type']).to eq(valid_note_params[:note][:type])
        end

        it 'creates the note for the current user' do
          expect(user.notes.reload.count).to eq(1)
        end

        it 'assigns the sent title to the created note' do
          expect(user.notes.reload.last.title).to eq(valid_note_params[:note][:title])
        end
      end

      context 'when creating a note with type critique' do
        let(:critique_params) do
          { note: valid_note_params[:note].merge(type: 'critique') }
        end

        before { post :create, params: critique_params }

        it 'responds with 201 status' do
          expect(response).to have_http_status(:created)
        end

        it 'creates the note with type critique' do
          expect(response_body['type']).to eq('critique')
        end
      end

      context 'when the note param is missing' do
        before { post :create, params: {} }

        it_behaves_like 'bad request when a parameter is missing', 'note'
      end

      context 'when title is missing' do
        before do
          post :create, params: {
            note: valid_note_params[:note].except(:title)
          }
        end

        it_behaves_like 'bad request when a parameter is missing', 'title'
      end

      context 'when content is missing' do
        before do
          post :create, params: {
            note: valid_note_params[:note].except(:content)
          }
        end

        it_behaves_like 'bad request when a parameter is missing', 'content'
      end

      context 'when type is missing' do
        before do
          post :create, params: {
            note: valid_note_params[:note].except(:type)
          }
        end

        it_behaves_like 'bad request when a parameter is missing', 'type'
      end

      context 'when note type is invalid' do
        before do
          post :create, params: {
            note: valid_note_params[:note].merge(type: 'invalid_type')
          }
        end

        it 'responds with 422 status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the invalid_note_type error message' do
          expect(response_body['errors'].first['message'])
            .to eq(I18n.t('errors.messages.invalid_note_type'))
        end
      end

      context 'when user does not belong to the utility in context' do
        before do
          request.headers['Utility-ID'] = create(:north_utility).code
          post :create, params: valid_note_params
        end

        it 'responds with 422 status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns the user_utility_mismatch error message' do
          expect(response_body['errors'].first['message'])
            .to eq(I18n.t('errors.messages.user_utility_mismatch'))
        end
      end

      context 'when review content exceeds word limit' do
        let(:utility) { create(:north_utility) }
        let(:user) { create(:user, utility: utility) }
        let(:over_limit_content) { Faker::Lorem.words(number: 51).join(' ') }

        before do
          request.headers['Utility-ID'] = utility.code
          post :create, params: {
            note: valid_note_params[:note].merge(content: over_limit_content, type: 'review')
          }
        end

        it 'responds with 400 status' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns validation errors' do
          expect(response_body['errors']).to be_present
        end

        it 'returns error detail for validation' do
          expect(response_body['errors'].first['detail']).to be_present
        end
      end

      context 'when title is blank' do
        before do
          post :create, params: {
            note: valid_note_params[:note].merge(title: '')
          }
        end

        it 'responds with 400 status' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns validation errors for title' do
          expect(response_body['errors']).to be_present
        end
      end

      context 'when content is blank' do
        before do
          post :create, params: {
            note: valid_note_params[:note].merge(content: '')
          }
        end

        it 'responds with 400 status' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns validation errors for content' do
          expect(response_body['errors']).to be_present
        end
      end
    end

    context 'when Utility-ID header is missing' do
      include_context 'with authenticated user'

      before { post :create, params: valid_note_params }

      it 'responds with 400 status' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns the param is missing error' do
        expect(response_body['errors'].first['message'])
          .to eq(I18n.t('errors.messages.internal_server_error'))
      end
    end

    context 'when there is not a user logged in' do
      before do
        request.headers['Utility-ID'] = create(:north_utility).code
        post :create, params: valid_note_params
      end

      it_behaves_like 'unauthorized'
    end
  end
end
