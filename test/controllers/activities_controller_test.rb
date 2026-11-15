require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "shows activity from followed users" do
    posts(:ruby).create_activity :create, owner: users(:bob)
    posts(:cooking).create_activity :create, owner: users(:carol)

    sign_in users(:alice)
    get activities_path
    assert_response :success
    assert_select "li", text: /published\s+#{posts(:ruby).title}/
    assert_select "li", text: /#{posts(:cooking).title}/, count: 0
  end
end
