class TicketsController < ApplicationController
  def create
    CreateTicketTransaction.new.call(params.to_unsafe_h) do |m|
      m.success do |ticket|
        render json: { success: true, ticket: ticket }, status: :ok
      end

      m.failure :validate do |errors|
        render json: { success: false, errors: errors }, status: :unprocessable_entity
      end

      m.failure do |error|
        render json: { success: false, errors: [error] }, status: :internal_server_error
      end
    end
  end
end
