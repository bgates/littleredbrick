class TestController < ActionController::Base
  def initialize
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    send(:initialize_current_url)
  end
end

