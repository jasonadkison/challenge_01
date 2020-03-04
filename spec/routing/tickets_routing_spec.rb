require "rails_helper"

RSpec.describe "routes for Tickets", type: :routing do
  it "is routed correctly" do
    expect(post: "/tickets").to route_to("tickets#create")
  end
end
