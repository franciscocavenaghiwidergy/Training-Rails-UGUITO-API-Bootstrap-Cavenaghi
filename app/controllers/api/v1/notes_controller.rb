module Api
  module V1
    class NotesController < ApplicationController
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

      private

      def notes_filtered
        @notes_filtered ||= notes_scope
          .where(filtering_params)
          .order(order_clause)
          .page(params[:page])
          .per(params[:page_size])
      end

      def notes_scope
        Note.all
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
        @note ||= Note.find(params[:id])
      end
    end
  end
end
