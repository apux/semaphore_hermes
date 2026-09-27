require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { User.take }

  describe "GET /session/new" do
    it "renders the login form" do
      get new_session_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /session" do
    it "signs in with valid credentials" do
      post session_path, params: { email_address: user.email_address, password: "password" }

      expect(response).to redirect_to(welcome_path)
      expect(cookies[:session_id]).to be_present
    end

    it "rejects invalid credentials" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }

      expect(response).to redirect_to(new_session_path)
      expect(cookies[:session_id]).to be_nil
    end
  end

  describe "DELETE /session" do
    it "signs out" do
      sign_in_as(user)

      delete session_path

      expect(response).to redirect_to(root_path)
      expect(cookies[:session_id]).to be_blank
    end
  end
end
