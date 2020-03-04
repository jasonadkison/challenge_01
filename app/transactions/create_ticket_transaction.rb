require 'net/http'

class CreateTicketTransaction
  include Dry::Transaction

  class WebhookError < StandardError; end

  step :validate
  step :finalize

  def validate(input)
    result = TicketContract.new.call(input)
    return Failure(result.errors(full: true)) unless result.success?

    Success(result.to_h)
  end

  def finalize(input)
    error = nil

    # Assuming that any changes should be rolled back on any error
    ActiveRecord::Base.transaction do
      ticket = persist_ticket!(user_id: input[:user_id], title: input[:title])
      persist_tags!(input[:tags].map(&:downcase).uniq)
      send_webhook!(tag_with_highest_count)
      return Success(ticket)
    rescue WebhookError
      error = "webhook request failed and no data was saved"
      raise ActiveRecord::Rollback
    rescue ActiveRecord::Rollback
      error = "a save error prevented any data from being saved"
    rescue StandardError
      error = "an error prevented any data from being saved"
      raise ActiveRecord::Rollback
    end

    Failure(error)
  end

  def persist_ticket!(user_id:, title:)
    Ticket.create!(user_id: user_id, title: title)
  end

  # TODO: this should be better optimized to reduce queries
  def persist_tags!(tag_names)
    tag_names.each do |name|
      Tag.where(name: name).first_or_create!.increment!(:count)
    end
  end

  # TODO: move into separate class
  def send_webhook!(tag)
    response = Net::HTTP.post(
      URI("https://webhook.site/b069a239-60dd-47ec-9dba-1f4295639a8d"),
      { tag: tag.name }.to_json,
      "Content-Type": "application/json"
    )

    raise WebhookError unless response.is_a?(Net::HTTPSuccess)
  end

  # TODO: move to separate class
  def tag_with_highest_count
    Tag.order(count: :desc).first
  end
end
