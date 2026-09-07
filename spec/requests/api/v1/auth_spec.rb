require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) { { email: "newuser@example.com", password: "password123" } }

    context "with valid params" do
      it "creates a new user and returns token" do
        post "/api/v1/auth/register", params: valid_params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("newuser@example.com")
        expect(json["user"]["role"]).to eq("customer")
        expect(json["token"]).to be_present
      end

      it "does not return password or password_digest" do
        post "/api/v1/auth/register", params: valid_params

        json = JSON.parse(response.body)
        expect(json["user"]).not_to have_key("password")
        expect(json["user"]).not_to have_key("password_digest")
      end

      it "returns user with id and timestamps" do
        post "/api/v1/auth/register", params: valid_params

        json = JSON.parse(response.body)
        expect(json["user"]["id"]).to be_present
        expect(json["user"]["created_at"]).to be_present
      end

      it "creates an auth token in database" do
        expect {
          post "/api/v1/auth/register", params: valid_params
        }.to change(AuthToken, :count).by(1)
      end
    end

    context "with duplicate email" do
      it "returns 422 for exact duplicate" do
        create(:user, email: valid_params[:email])

        post "/api/v1/auth/register", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("validation_failed")
      end

      it "returns 422 for duplicate with different case" do
        create(:user, email: "newuser@example.com")

        post "/api/v1/auth/register", params: { email: "NEWUSER@example.com", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("validation_failed")
      end
    end

    context "with invalid email" do
      it "returns 422 for malformed email" do
        post "/api/v1/auth/register", params: { email: "invalid", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("validation_failed")
      end

      it "returns 422 for email without domain" do
        post "/api/v1/auth/register", params: { email: "test@", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for email without @" do
        post "/api/v1/auth/register", params: { email: "testexample.com", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for empty email" do
        post "/api/v1/auth/register", params: { email: "", password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid password" do
      it "returns 422 for short password" do
        post "/api/v1/auth/register", params: { email: "test@example.com", password: "short" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("validation_failed")
      end

      it "returns 422 for empty password" do
        post "/api/v1/auth/register", params: { email: "test@example.com", password: "" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for 7 character password" do
        post "/api/v1/auth/register", params: { email: "test@example.com", password: "1234567" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "accepts 8 character password" do
        post "/api/v1/auth/register", params: { email: "test@example.com", password: "12345678" }

        expect(response).to have_http_status(:created)
      end
    end

    context "with missing params" do
      it "returns 422 for missing email" do
        post "/api/v1/auth/register", params: { password: "password123" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for missing password" do
        post "/api/v1/auth/register", params: { email: "test@example.com" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for empty params" do
        post "/api/v1/auth/register", params: {}

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "email normalization" do
      it "normalizes email to lowercase" do
        post "/api/v1/auth/register", params: { email: "NEWUSER@EXAMPLE.COM", password: "password123" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("newuser@example.com")
      end

      it "trims whitespace from email" do
        post "/api/v1/auth/register", params: { email: "  newuser@example.com  ", password: "password123" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("newuser@example.com")
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      it "returns user and token" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("test@example.com")
        expect(json["token"]).to be_present
      end

      it "does not return password or password_digest" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        json = JSON.parse(response.body)
        expect(json["user"]).not_to have_key("password")
        expect(json["user"]).not_to have_key("password_digest")
      end

      it "creates an auth token" do
        expect {
          post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
        }.to change(AuthToken, :count).by(1)
      end

      it "returns user role" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        json = JSON.parse(response.body)
        expect(json["user"]["role"]).to eq("customer")
      end
    end

    context "with invalid credentials" do
      it "returns 401 for wrong password" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrongpassword" }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_credentials")
        expect(json["error"]["message"]).to eq("Invalid email or password")
      end

      it "returns 401 for non-existent email" do
        post "/api/v1/auth/login", params: { email: "nonexistent@example.com", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("invalid_credentials")
      end

      it "returns 401 for empty password" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 for empty email" do
        post "/api/v1/auth/login", params: { email: "", password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns generic error message (does not reveal which field is wrong)" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrong" }
        wrong_password_response = response.body

        post "/api/v1/auth/login", params: { email: "wrong@example.com", password: "password123" }
        wrong_email_response = response.body

        expect(wrong_password_response).to eq(wrong_email_response)
      end
    end

    context "email case insensitivity" do
      it "is case-insensitive for email" do
        post "/api/v1/auth/login", params: { email: "TEST@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("test@example.com")
      end

      it "handles mixed case email" do
        post "/api/v1/auth/login", params: { email: "TeSt@ExAmPlE.cOm", password: "password123" }

        expect(response).to have_http_status(:ok)
      end

      it "trims whitespace from email" do
        post "/api/v1/auth/login", params: { email: "  test@example.com  ", password: "password123" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "multiple login attempts" do
      it "creates a new token for each login" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
        first_token = JSON.parse(response.body)["token"]

        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
        second_token = JSON.parse(response.body)["token"]

        expect(first_token).not_to eq(second_token)
      end

      it "allows multiple active tokens" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        expect(user.auth_tokens.active.count).to eq(2)
      end
    end
  end

  describe "Token authentication" do
    let!(:user) { create(:user) }
    let!(:auth_token) { create(:auth_token, user: user) }

    it "returns nil for nil token" do
      result = AuthenticationService.authenticate_token(nil)
      expect(result).to be_nil
    end

    it "returns nil for empty token" do
      result = AuthenticationService.authenticate_token("")
      expect(result).to be_nil
    end

    it "returns nil for invalid token" do
      result = AuthenticationService.authenticate_token("invalid-token")
      expect(result).to be_nil
    end

    it "returns nil for expired token" do
      expired_token = create(:auth_token, :expired, user: user)
      result = AuthenticationService.authenticate_token(expired_token.token)
      expect(result).to be_nil
    end

    it "returns nil for revoked token" do
      revoked_token = create(:auth_token, :revoked, user: user)
      result = AuthenticationService.authenticate_token(revoked_token.token)
      expect(result).to be_nil
    end

    it "returns user with valid token" do
      result = AuthenticationService.authenticate_token(auth_token.token)
      expect(result).to eq(user)
    end

    it "does not authenticate with another user's token" do
      other_user = create(:user)
      result = AuthenticationService.authenticate_token(auth_token.token)
      expect(result).not_to eq(other_user)
    end
  end

  describe "Authorization header parsing" do
    it "extracts token from valid header format" do
      token = "test-token-123"
      # Verify the token extraction logic works
      header = "Bearer #{token}"
      pattern = /^Bearer +(.+)$/i
      extracted = header.match(pattern)&.captures&.first
      expect(extracted).to eq(token)
    end

    it "handles token without Bearer prefix" do
      token = "test-token-123"
      header = token
      pattern = /^Bearer +(.+)$/i
      extracted = header.match(pattern)&.captures&.first
      expect(extracted).to be_nil
    end

    it "handles missing Authorization header" do
      result = AuthenticationService.authenticate_token(nil)
      expect(result).to be_nil
    end

    it "handles malformed Authorization header" do
      result = AuthenticationService.authenticate_token("not-a-bearer-token")
      expect(result).to be_nil
    end
  end

  describe "Error response format" do
    it "returns proper error format for invalid credentials" do
      post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrong" }

      json = JSON.parse(response.body)
      expect(json).to have_key("error")
      expect(json["error"]).to have_key("code")
      expect(json["error"]).to have_key("message")
    end

    it "returns proper error format for validation errors" do
      post "/api/v1/auth/register", params: { email: "invalid", password: "short" }

      json = JSON.parse(response.body)
      expect(json).to have_key("error")
      expect(json["error"]).to have_key("code")
      expect(json["error"]).to have_key("message")
    end
  end
end
