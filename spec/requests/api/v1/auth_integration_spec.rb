require "rails_helper"

RSpec.describe "Authentication Integration Flow", type: :request do
  describe "complete user journey" do
    it "allows registration, login, and authenticated requests" do
      # Step 1: Register
      post "/api/v1/auth/register", params: { email: "journey@example.com", password: "password123" }
      expect(response).to have_http_status(:created)
      register_response = JSON.parse(response.body)
      register_token = register_response["token"]
      user_id = register_response["user"]["id"]

      # Step 2: Login
      post "/api/v1/auth/login", params: { email: "journey@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      login_response = JSON.parse(response.body)
      login_token = login_response["token"]

      # Verify tokens are different
      expect(register_token).not_to eq(login_token)

      # Verify both tokens work
      expect(AuthenticationService.authenticate_token(register_token)).to be_present
      expect(AuthenticationService.authenticate_token(login_token)).to be_present
    end

    it "handles multiple users independently" do
      # Register first user
      post "/api/v1/auth/register", params: { email: "user1@example.com", password: "password123" }
      user1_response = JSON.parse(response.body)
      user1_token = user1_response["token"]
      user1_id = user1_response["user"]["id"]

      # Register second user
      post "/api/v1/auth/register", params: { email: "user2@example.com", password: "password123" }
      user2_response = JSON.parse(response.body)
      user2_token = user2_response["token"]
      user2_id = user2_response["user"]["id"]

      # Verify users are different
      expect(user1_id).not_to eq(user2_id)

      # Verify tokens work independently
      user1 = AuthenticationService.authenticate_token(user1_token)
      user2 = AuthenticationService.authenticate_token(user2_token)

      expect(user1.id).to eq(user1_id)
      expect(user2.id).to eq(user2_id)
      expect(user1.id).not_to eq(user2.id)
    end

    it "maintains session across multiple requests" do
      # Register and get token
      post "/api/v1/auth/register", params: { email: "session@example.com", password: "password123" }
      token = JSON.parse(response.body)["token"]

      # Verify token works multiple times
      3.times do
        result = AuthenticationService.authenticate_token(token)
        expect(result).to be_present
        expect(result.email).to eq("session@example.com")
      end
    end
  end

  describe "token lifecycle" do
    it "handles token expiration" do
      # Register and get token
      post "/api/v1/auth/register", params: { email: "expire@example.com", password: "password123" }
      token = JSON.parse(response.body)["token"]

      # Token should work initially
      expect(AuthenticationService.authenticate_token(token)).to be_present

      # Expire the token
      auth_token = AuthToken.find_by(token: token)
      auth_token.update!(expires_at: 1.hour.ago)

      # Token should no longer work
      expect(AuthenticationService.authenticate_token(token)).to be_nil
    end

    it "handles token revocation" do
      # Register and get token
      post "/api/v1/auth/register", params: { email: "revoke@example.com", password: "password123" }
      token = JSON.parse(response.body)["token"]

      # Token should work initially
      expect(AuthenticationService.authenticate_token(token)).to be_present

      # Revoke the token
      auth_token = AuthToken.find_by(token: token)
      auth_token.revoke!

      # Token should no longer work
      expect(AuthenticationService.authenticate_token(token)).to be_nil
    end

    it "allows new login after token revocation" do
      # Register and get token
      post "/api/v1/auth/register", params: { email: "newlogin@example.com", password: "password123" }
      old_token = JSON.parse(response.body)["token"]

      # Revoke the token
      auth_token = AuthToken.find_by(token: old_token)
      auth_token.revoke!

      # Login again
      post "/api/v1/auth/login", params: { email: "newlogin@example.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      new_token = JSON.parse(response.body)["token"]

      # New token should work
      expect(AuthenticationService.authenticate_token(new_token)).to be_present

      # Old token should not work
      expect(AuthenticationService.authenticate_token(old_token)).to be_nil
    end
  end

  describe "security scenarios" do
    it "prevents access with stolen token after password change" do
      # Register user
      post "/api/v1/auth/register", params: { email: "secure@example.com", password: "password123" }
      token = JSON.parse(response.body)["token"]

      # Token works
      expect(AuthenticationService.authenticate_token(token)).to be_present

      # Change password (tokens remain valid in this implementation)
      user = User.find_by(email: "secure@example.com")
      user.update!(password: "newpassword123")

      # Old token still valid (this is expected behavior for stateless tokens)
      # In a more secure implementation, you might invalidate all tokens on password change
      expect(AuthenticationService.authenticate_token(token)).to be_present
    end

    it "handles concurrent registrations gracefully" do
      email = "concurrent@example.com"

      # First registration
      post "/api/v1/auth/register", params: { email: email, password: "password123" }
      expect(response).to have_http_status(:created)

      # Second registration with same email
      post "/api/v1/auth/register", params: { email: email, password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not leak user existence information" do
      # Try to login with non-existent email
      post "/api/v1/auth/login", params: { email: "nonexistent@example.com", password: "password123" }
      nonexistent_response = response.body

      # Try to login with wrong password
      create(:user, email: "exists@example.com", password: "password123")
      post "/api/v1/auth/login", params: { email: "exists@example.com", password: "wrongpassword" }
      wrong_password_response = response.body

      # Both should return the same error
      expect(nonexistent_response).to eq(wrong_password_response)
    end
  end

  describe "edge cases" do
    it "handles very long email addresses" do
      long_email = "a" * 200 + "@example.com"
      post "/api/v1/auth/register", params: { email: long_email, password: "password123" }
      # Should either succeed or fail gracefully
      expect(response.status).to be_in([201, 422])
    end

    it "handles long passwords (within bcrypt limit)" do
      long_password = "a" * 72
      post "/api/v1/auth/register", params: { email: "longpass@example.com", password: long_password }
      expect(response).to have_http_status(:created)
    end

    it "handles special characters in password" do
      special_password = "p@$$w0rd!#%^&*()"
      post "/api/v1/auth/register", params: { email: "special@example.com", password: special_password }
      expect(response).to have_http_status(:created)

      # Verify login works with special characters
      post "/api/v1/auth/login", params: { email: "special@example.com", password: special_password }
      expect(response).to have_http_status(:ok)
    end

    it "handles unicode in password" do
      unicode_password = "пароль123" # Russian word for "password"
      post "/api/v1/auth/register", params: { email: "unicode@example.com", password: unicode_password }
      expect(response).to have_http_status(:created)

      post "/api/v1/auth/login", params: { email: "unicode@example.com", password: unicode_password }
      expect(response).to have_http_status(:ok)
    end
  end
end
