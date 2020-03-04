require "rails_helper"

RSpec.describe CreateTicketTransaction, type: :transaction do
  subject { described_class.new.call(params) }

  let(:webhook_url) { /webhook.site/i }

  let(:params) do
    {
      user_id: 1234,
      title: "My title",
      tags: ["tag1", "tag2"]
    }
  end

  before do
    stub_request(:post, webhook_url)
  end

  context "valid params" do
    it { is_expected.to be_success }

    it "creates a new ticket" do
      expect { subject }.to change { Ticket.count }.by(1)
    end

    it "creates new tags" do
      expect { subject }.to change { Tag.count }.by(params[:tags].size)
    end

    it "increments count of existing tag" do
      Tag.create(name: params[:tags].first, count: 5)
      expect { subject }.to change { Tag.first.count }.from(5).to(6)
    end

    it "sends tag_with_highest_count to webhook url" do
      tag = double(name: 'test')
      allow_any_instance_of(described_class).to receive(:tag_with_highest_count).and_return(tag)
      subject
      expect(
        a_request(:post, webhook_url)
          .with(body: {"tag": "test"}, headers: {'Content-Type': 'application/json'})
      ).to have_been_made
    end
  end

  # TODO: write specs for failure scenarios
end
