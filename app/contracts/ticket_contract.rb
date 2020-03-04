class TicketContract < Dry::Validation::Contract
  params do
    # user_id must be present and can be either an integer or string
    required(:user_id) { filled? & (int? | str?) }

    # title must be present and can be either an integer or string
    required(:title) { filled? & (int? | str?) }

    # tags must be present and must be an array containing 0 to 4 strings
    required(:tags).value(type?: Array, max_size?: 4).each(:str?)
  end
end
