require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { User.take }

  describe "GET /passwords/new" do
    it "renders the reset form" do
      get new_password_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    it "emails reset instructions" do
      expect {
        post passwords_path, params: { email_address: user.email_address }
      }.to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect_notice("reset instructions sent")
    end

    it "redirects for an unknown user and sends no mail" do
      expect {
        post passwords_path, params: { email_address: "missing-user@example.com" }
      }.not_to have_enqueued_mail

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect_notice("reset instructions sent")
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the edit form" do
      get edit_password_path(user.password_reset_token)

      expect(response).to have_http_status(:success)
    end

    it "rejects an invalid password reset token" do
      get edit_password_path("invalid token")

      expect(response).to redirect_to(new_password_path)
      follow_redirect!
      expect_notice("reset link is invalid")
    end
  end

  describe "PUT /passwords/:token" do
    it "resets the password" do
      expect {
        put password_path(user.password_reset_token), params: { password: "new", password_confirmation: "new" }
        expect(response).to redirect_to(new_session_path)
      }.to change { user.reload.password_digest }

      follow_redirect!
      expect_notice("Password has been reset")
    end

    it "rejects non matching passwords" do
      token = user.password_reset_token

      expect {
        put password_path(token), params: { password: "no", password_confirmation: "match" }
        expect(response).to redirect_to(edit_password_path(token))
      }.not_to change { user.reload.password_digest }

      follow_redirect!
      expect_notice("Passwords did not match")
    end
  end

  def expect_notice(text)
    expect(html).to have_css("div", text: /#{Regexp.escape(text)}/)
  end
end
