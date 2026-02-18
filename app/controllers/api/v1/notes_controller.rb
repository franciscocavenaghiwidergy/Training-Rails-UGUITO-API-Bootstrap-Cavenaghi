module Api
  module V1
    class NotesController < ApplicationController
      def index
        render json: notes_filtered, status: :ok, each_serializer: IndexNoteSerializer
      end

      def show
        render json: Note.find(params.require(:id)), status: :ok, serializer: ShowNoteSerializer
      end

      private

      def notes_filtered
        @notes_filtered ||= Note
          .where(filtering_params)
          .order(created_at: order_direction)
          .page(index_params[:page])
          .per(index_params[:page_size])
      end

      def filtering_params
        return {} unless valid_note_type?(type_param)

        { note_type: type_param }
      end

      def type_param
        params[:type]
      end

      def valid_note_type?(type)
        type.present? && Note.note_types.key?(type)
      end

      def order_direction
        index_params[:order].to_s.downcase == 'asc' ? :asc : :desc
      end

      def index_params
        params.permit(:type, :order, :page, :page_size)
      end
    end
  end
end
