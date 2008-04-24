require File.dirname(__FILE__) + '/../test_helper'
require 'snitch_controller'

# Re-raise errors caught by the controller.
class SnitchController; def rescue_action(e) raise e end; end

class SnitchControllerTest < Test::Unit::TestCase 
  all_helpers
  all_fixtures

  def setup 
    puts "Calling setup..."
    @controller = SnitchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_refresh 
    @request.session[:last_pull] = Time.gm( 2007, "apr", 27, 1, 0 )
    get :refresh
    assert_response :success 
  end            
end
