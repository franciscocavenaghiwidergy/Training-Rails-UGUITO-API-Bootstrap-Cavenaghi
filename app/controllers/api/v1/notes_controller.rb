module Api
  module V1
    class NotesController < ApplicationController
      before_action :authenticate_user!
      before_action :utility, only: [:create]

      def index
        render json: notes_filtered,
               status: :ok,
               each_serializer: IndexNoteSerializer
      end

      def show
        render json: note,
               status: :ok,
               serializer: ShowNoteSerializer
      end

      def create
        note_params = params.require(:note)
        note_params.require(:title)
        note_params.require(:content)
        note_params.require(:type)
        permitted = note_params.permit(:title, :content, :type)

        raise Exceptions::InvalidParameterError, 'invalid_note_type' unless valid_note_type?(permitted[:type])
        ensure_user_utility_in_context!

        new_note = current_user.notes.build(build_note_attributes(permitted))

        if new_note.save
          render json: new_note, status: :created, serializer: ShowNoteSerializer
        else
          validation_error(new_note)
        end
      end

      def index_async
        response = execute_async(RetrieveNotesWorker, current_user.id, index_async_params)
        async_custom_response(response)
      end

      private

      def ensure_user_utility_in_context!
        return if current_user.utility_id == utility.id

        raise Exceptions::InvalidParameterError, 'user_utility_mismatch'
      end

      def build_note_attributes(permitted)
        {
          title: permitted[:title],
          content: permitted[:content],
          note_type: permitted[:type]
        }
      end

      def notes_filtered
        @notes_filtered ||= notes_scope
          .where(filtering_params)
          .order(order_clause)
          .page(params[:page])
          .per(params[:page_size])
      end

      def notes_scope
        current_user.notes
      end

      def filtering_params
        return {} unless valid_note_type?(params[:type])

        { note_type: params[:type] }
      end

      def valid_note_type?(type)
        type.present? && Note.note_types.key?(type)
      end

      def order_clause
        direction = params[:order].to_s.downcase == 'asc' ? :asc : :desc
        { created_at: direction }
      end

      def note
        @note ||= current_user.notes.find(params[:id])
      end

      def index_async_params
        { author: params.require(:author) }
      end
    end
  end
end
