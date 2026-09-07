# Request spec helpers
module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    # Will be implemented in Phase 1 with token authentication
    { "Authorization" => "Bearer #{user.auth_token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
