require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "identifies the signed-in member" do
    user = create(:user)
    warden = instance_double(Warden::Proxy)
    allow(warden).to receive(:user).with(:user).and_return(user)

    connect "/cable", env: { "warden" => warden }

    expect(connection.current_user).to eq(user)
  end

  it "rejects anonymous visitors" do
    warden = instance_double(Warden::Proxy, user: nil)
    expect { connect "/cable", env: { "warden" => warden } }.to have_rejected_connection
  end

  it "rejects connections without a Warden session" do
    expect { connect "/cable" }.to have_rejected_connection
  end
end
