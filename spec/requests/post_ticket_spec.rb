require "rails_helper"

RSpec.describe "POST /tickets", type: :request do
  let(:params) do
    {
      user_id: 1234,
      title: "My title",
      tags: ["tag1", "tag2"]
    }
  end

  before do
    stub_request(:post, /webhook.site/i)
  end

  it "creates the valid ticket" do
    expect { post_ticket(params) }.to change { Ticket.count }.by(1)
  end

  it "creates tags" do
    expect { post_ticket(params) }.to change { Tag.count }.by(params[:tags].size)
  end

  it "increments existing tag count" do
    Tag.create(name: params[:tags].first, count: 5)
    expect {
      post_ticket(params)
    }.to change { Tag.first.count }.from(5).to(6)
  end

  it "handles tags case-insensitive" do
    Tag.create(name: 'foobar', count: 5)
    params[:tags][0] = 'FooBAR'
    expect {
      post_ticket(params)
    }.to change { Tag.first.count }.from(5).to(6)
  end

  describe "user_id validations" do
    it "must be present" do
      params.delete(:user_id)
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/user_id is missing/i)
    end

    it "rejects nil" do
      params[:user_id] = nil
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/user_id must be filled/i)
    end

    it "rejects blank" do
      params[:user_id] = ""
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/user_id must be filled/i)
    end
  end

  describe "title validations" do
    it "must be present" do
      params.delete(:title)
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/title is missing/i)
    end

    it "rejects nil" do
      params[:title] = nil
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/title must be filled/i)
    end

    it "rejects blank" do
      params[:title] = ""
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/title must be filled/i)
    end
  end

  describe "tags validation" do
    it "must be present" do
      params.delete(:tags)
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/tags is missing/i)
    end

    it "must be an array" do
      params[:tags] = ""
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/tags must be array/i)
    end

    it "must have less than 5 items" do
      params[:tags] = ["one", "two", "three", "four", "five"]
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/tags size cannot be greater than 4/i)
    end

    it "must contain only strings" do
      params[:tags] << 123
      expect { post_ticket(params) }.to_not change { Ticket.count }
      expect(response_error['text']).to match(/#{params[:tags].size - 1} must be a string/i)
    end
  end

  private

  def post_ticket(params)
    post "/tickets", params: params.to_json, headers: { "CONTENT_TYPE" => "application/json" }
  end

  def response_error
    JSON.parse(response.body)['errors'].first
  end
end
