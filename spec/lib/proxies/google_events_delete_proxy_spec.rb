require "spec_helper"

describe GoogleEventsDeleteProxy do
  let(:user_id) { rand(999999).to_s }

  context "fake event deletion", if: Rails.env.test? do
    before(:each) do
      fake_proxy = GoogleEventsDeleteProxy.new(fake: true, fake_options: { match_requests_on: [:method, :path] })
      GoogleEventsDeleteProxy.stub(:new).and_return(fake_proxy)
    end

    context "existing event" do
      subject { GoogleEventsDeleteProxy.new(user_id).delete_event("evil_event") }

      its(:status) { should eq(204) }
      it { subject.response[:body].should be_blank }
    end

    context "non-existing event (404)" do
      subject { GoogleEventsDeleteProxy.new(user_id).delete_event("non_existent") }

      its(:status) { should eq(404) }
      it { subject.response[:body].should be_blank }
    end
  end

  context "real event deletion", testext: true do
    # Hard to simulate a real, existing event deletion by itself, so this will be bundled with
    # google_events_insert_proxy_spec.rb, and even then, still hard to verify

    before(:each) do
      real_proxy = GoogleEventsDeleteProxy.new(access_token: Settings.google_proxy.test_user_access_token,
                                               refresh_token: Settings.google_proxy.test_user_refresh_token,
                                               expiration_time: 0)
      GoogleEventsDeleteProxy.stub(:new).and_return(real_proxy)
    end

    context "non-existing event (404)" do
      subject { GoogleEventsDeleteProxy.new(user_id).delete_event("non_existent") }

      its(:status) { should eq(404) }
      it { subject.response[:body].should be_blank }
    end

  end
end