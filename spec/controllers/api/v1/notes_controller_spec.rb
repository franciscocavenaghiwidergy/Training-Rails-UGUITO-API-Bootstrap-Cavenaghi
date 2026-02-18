require 'rails_helper'

describe Api::V1::NotesController, type: :controller do
  describe 'GET #index' do
    let(:user_notes) { create_list(:note, 5, user: user) }

    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      let!(:expected) do
        ActiveModel::Serializer::CollectionSerializer.new(notes_expected,
                                                          serializer: IndexNoteSerializer).to_json
      end

      context 'when fetching all the notes for user' do
        let(:notes_expected) { user_notes.sort_by(&:created_at).reverse }

        before { get :index }

        it 'responds with the expected notes json' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching notes with page and page size params' do
        let(:page) { 1 }
        let(:page_size) { 2 }
        let(:notes_expected) { user_notes.sort_by(&:created_at).reverse.first(2) }

        before { get :index, params: { page: page, page_size: page_size } }

        it 'responds with the expected notes' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching notes using type filter' do
        let!(:review_notes) { create_list(:note, 2, user: user, note_type: :review) }
        let!(:critique_notes) { create_list(:note, 2, user: user, note_type: :critique) }
        let(:notes_expected) { critique_notes.sort_by(&:created_at).reverse }

        before { get :index, params: { type: 'critique' } }

        it 'responds with expected notes filtered by type' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching notes with invalid type filter' do
        let(:notes_expected) { user_notes.sort_by(&:created_at).reverse }

        before { get :index, params: { type: 'invalid_type' } }

        it 'responds with all user notes (filter ignored)' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'when there is not a user logged in' do
      context 'when fetching all the notes for user' do
        before { get :index }

        it_behaves_like 'unauthorized'
      end
    end
  end

  describe 'GET #show' do
    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      let(:expected) { ShowNoteSerializer.new(note, root: false).to_json }

      context 'when fetching a valid note' do
        let(:note) { create(:note, user: user) }

        before { get :show, params: { id: note.id } }

        it 'responds with the note json' do
          expect(response.body).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching an invalid note (non-existent id)' do
        before { get :show, params: { id: Faker::Number.number } }

        it 'responds with 404 status' do
          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when fetching a note that belongs to another user' do
        let(:other_user) { create(:user) }
        let(:other_user_note) { create(:note, user: other_user) }

        before { get :show, params: { id: other_user_note.id } }

        it 'responds with 404 status' do
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when there is not a user logged in' do
      context 'when fetching a note' do
        before { get :show, params: { id: Faker::Number.number } }

        it_behaves_like 'unauthorized'
      end
    end
  end

  describe 'POST #create' do
    let(:valid_note_params) do
      {
        note: {
          title: Faker::Lorem.sentence,
          content: Faker::Lorem.paragraph,
          type: 'review'
        }
      }
    end

    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      before { request.headers['Utility-ID'] = user.utility.code }

      context 'when creating a note with valid params (happy path)' do
        before { post :create, params: valid_note_params }

        it 'responds with 201 status' do
          expect(response).to have_http_status(:created)
        end

        it 'responds with the created note json' do
          expect(response_body['id']).to be_present
          expect(response_body['title']).to eq(valid_note_params[:note][:title])
          expect(response_body['content']).to eq(valid_note_params[:note][:content])
          expect(response_body['type']).to eq('review')
        end

        it 'creates the note for the current user' do
          expect(user.notes.reload.count).to eq(1)
          expect(user.notes.last.title).to eq(valid_note_params[:note][:title])
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
        let(:missing_parameter) { 'note' }

        before { post :create, params: {} }

        it_behaves_like 'bad request when a parameter is missing'
      end

      context 'when title is missing' do
        let(:missing_parameter) { 'title' }

        before do
          post :create, params: {
            note: valid_note_params[:note].except(:title)
          }
        end

        it_behaves_like 'bad request when a parameter is missing'
      end

      context 'when content is missing' do
        let(:missing_parameter) { 'content' }

        before do
          post :create, params: {
            note: valid_note_params[:note].except(:content)
          }
        end

        it_behaves_like 'bad request when a parameter is missing'
      end

      context 'when type is missing' do
        let(:missing_parameter) { 'type' }

        before do
          post :create, params: {
            note: valid_note_params[:note].except(:type)
          }
        end

        it_behaves_like 'bad request when a parameter is missing'
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

  describe 'GET #index_async' do
    context 'when the user is authenticated' do
      include_context 'with authenticated user'

      let(:author) { Faker::Book.author }
      let(:params) { { author: author } }
      let(:worker_name) { 'RetrieveNotesWorker' }
      let(:parameters) { [user.id, params] }

      before { get :index_async, params: params }

      it 'returns status code accepted' do
        expect(response).to have_http_status(:accepted)
      end

      it 'returns the response id and url to retrieve the data later' do
        expect(response_body.keys).to contain_exactly('response', 'job_id', 'url')
      end

      it 'enqueues a job' do
        expect(AsyncRequest::JobProcessor.jobs.size).to eq(1)
      end

      it 'creates the right job' do
        expect(AsyncRequest::Job.last.worker).to eq(worker_name)
      end

      it 'creates a job with given parameters' do
        expect(AsyncRequest::Job.last.params).to eq(parameters)
      end
    end

    context 'when the user is not authenticated' do
      before { get :index_async }

      it 'returns status code unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
