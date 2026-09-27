require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "landing page is public and links to login" do
    get root_path

    assert_response :success
    assert_select "a.button-primary", text: "Log in"
  end

  test "welcome page requires login" do
    get welcome_path

    assert_redirected_to new_session_path
  end

  test "welcome page greets the signed in user" do
    user = users(:one)
    sign_in_as(user)

    get welcome_path

    assert_response :success
    assert_select "h1", "Welcome"
    assert_match user.email_address, response.body
  end
end
