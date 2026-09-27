require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "is public and links to login" do
      get root_path

      expect(response).to have_http_status(:success)
      expect(html).to have_css("a.button-primary", text: "Log in")
    end
  end

  describe "GET /welcome" do
    it "requires login" do
      get welcome_path

      expect(response).to redirect_to(new_session_path)
    end

    it "greets the signed in user" do
      user = users(:one)
      sign_in_as(user)

      get welcome_path

      expect(response).to have_http_status(:success)
      expect(html).to have_css("h1", text: "Welcome")
      expect(response.body).to include(user.email_address)
    end
  end
end
