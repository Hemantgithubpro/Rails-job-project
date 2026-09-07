require "rails_helper"

RSpec.describe AuthenticationService do
  describe ".register" do
    let(:valid_params) { { email: "newuser@example.com", password: "password123" } }

    context "with valid params" do
      it "creates a new user" do
        expect {
          described_class.register(**valid_params)
        }.to change(User, :count).by(1)
      end

      it "returns user and token" do
        result = described_class.register(**valid_params)
        expect(result[:user]).to be_a(User)
        expect(result[:token]).to be_present
      end

      it "creates an auth token for the user" do
        result = described_class.register(**valid_params)
        expect(AuthToken.find_by(token: result[:token])).to be_present
      end

      it "assigns customer role by default" do
        result = described_class.register(**valid_params)
        expect(result[:user].role).to eq("customer")
      end

      it "normalizes email" do
        result = described_class.register(email: "NEW@EXAMPLE.COM", password: "password123")
        expect(result[:user].email).to eq("new@example.com")
      end

      it "creates token with 7 day expiration" do
        result = described_class.register(**valid_params)
        auth_token = AuthToken.find_by(token: result[:token])
        expected_expiration = 7.days.from_now
        expect(auth_token.expires_at).to be_within(1.minute).of(expected_expiration)
      end
    end

    context "with invalid params" do
      it "raises UserExistsError for duplicate email" do
        create(:user, email: valid_params[:email])
        expect {
          described_class.register(**valid_params)
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "raises UserExistsError for duplicate email case insensitive" do
        create(:user, email: "newuser@example.com")
        expect {
          described_class.register(email: "NEWUSER@example.com", password: "password123")
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "raises UserExistsError for invalid email" do
        expect {
          described_class.register(email: "invalid", password: "password123")
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "raises UserExistsError for short password" do
        expect {
          described_class.register(email: "test@example.com", password: "short")
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "raises UserExistsError for empty email" do
        expect {
          described_class.register(email: "", password: "password123")
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "raises UserExistsError for empty password" do
        expect {
          described_class.register(email: "test@example.com", password: "")
        }.to raise_error(AuthenticationService::UserExistsError)
      end

      it "does not create user on error" do
        create(:user, email: valid_params[:email])
        expect {
          begin
            described_class.register(**valid_params)
          rescue AuthenticationService::UserExistsError
            # expected
          end
        }.not_to change(User, :count)
      end

      it "does not create token on error" do
        create(:user, email: valid_params[:email])
        expect {
          begin
            described_class.register(**valid_params)
          rescue AuthenticationService::UserExistsError
            # expected
          end
        }.not_to change(AuthToken, :count)
      end
    end
  end

  describe ".login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      it "returns user and token" do
        result = described_class.login(email: "test@example.com", password: "password123")
        expect(result[:user]).to eq(user)
        expect(result[:token]).to be_present
      end

      it "creates an auth token for the user" do
        result = described_class.login(email: "test@example.com", password: "password123")
        expect(AuthToken.find_by(token: result[:token])).to be_present
      end

      it "increases token count" do
        expect {
          described_class.login(email: "test@example.com", password: "password123")
        }.to change(AuthToken, :count).by(1)
      end

      it "is case-insensitive for email" do
        result = described_class.login(email: "TEST@example.com", password: "password123")
        expect(result[:user]).to eq(user)
      end

      it "trims whitespace from email" do
        result = described_class.login(email: "  test@example.com  ", password: "password123")
        expect(result[:user]).to eq(user)
      end
    end

    context "with invalid credentials" do
      it "raises InvalidCredentialsError for wrong password" do
        expect {
          described_class.login(email: "test@example.com", password: "wrongpassword")
        }.to raise_error(AuthenticationService::InvalidCredentialsError, "Invalid email or password")
      end

      it "raises InvalidCredentialsError for non-existent email" do
        expect {
          described_class.login(email: "nonexistent@example.com", password: "password123")
        }.to raise_error(AuthenticationService::InvalidCredentialsError, "Invalid email or password")
      end

      it "raises InvalidCredentialsError for empty password" do
        expect {
          described_class.login(email: "test@example.com", password: "")
        }.to raise_error(AuthenticationService::InvalidCredentialsError)
      end

      it "raises InvalidCredentialsError for empty email" do
        expect {
          described_class.login(email: "", password: "password123")
        }.to raise_error(AuthenticationService::InvalidCredentialsError)
      end

      it "does not create token on error" do
        expect {
          begin
            described_class.login(email: "test@example.com", password: "wrong")
          rescue AuthenticationService::InvalidCredentialsError
            # expected
          end
        }.not_to change(AuthToken, :count)
      end

      it "returns generic error (does not reveal which field is wrong)" do
        wrong_password_error = nil
        wrong_email_error = nil

        begin
          described_class.login(email: "test@example.com", password: "wrong")
        rescue AuthenticationService::InvalidCredentialsError => e
          wrong_password_error = e.message
        end

        begin
          described_class.login(email: "wrong@example.com", password: "password123")
        rescue AuthenticationService::InvalidCredentialsError => e
          wrong_email_error = e.message
        end

        expect(wrong_password_error).to eq(wrong_email_error)
      end
    end

    context "with admin user" do
      let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

      it "allows admin login" do
        result = described_class.login(email: "admin@example.com", password: "password123")
        expect(result[:user]).to eq(admin)
        expect(result[:user].admin?).to be true
      end
    end
  end

  describe ".authenticate_token" do
    let!(:user) { create(:user) }
    let!(:auth_token) { create(:auth_token, user: user) }

    it "returns user for valid token" do
      result = described_class.authenticate_token(auth_token.token)
      expect(result).to eq(user)
    end

    it "returns nil for nil token" do
      result = described_class.authenticate_token(nil)
      expect(result).to be_nil
    end

    it "returns nil for empty token" do
      result = described_class.authenticate_token("")
      expect(result).to be_nil
    end

    it "returns nil for invalid token" do
      result = described_class.authenticate_token("invalid-token")
      expect(result).to be_nil
    end

    it "returns nil for expired token" do
      expired_token = create(:auth_token, :expired, user: user)
      result = described_class.authenticate_token(expired_token.token)
      expect(result).to be_nil
    end

    it "returns nil for revoked token" do
      revoked_token = create(:auth_token, :revoked, user: user)
      result = described_class.authenticate_token(revoked_token.token)
      expect(result).to be_nil
    end

    it "returns nil for token belonging to deleted user" do
      token_value = auth_token.token
      user.destroy
      result = described_class.authenticate_token(token_value)
      expect(result).to be_nil
    end

    it "does not authenticate with another user's token" do
      other_user = create(:user)
      result = described_class.authenticate_token(auth_token.token)
      expect(result).not_to eq(other_user)
    end
  end

  describe "error classes" do
    it "InvalidCredentialsError inherits from AuthenticationError" do
      expect(AuthenticationService::InvalidCredentialsError.superclass).to eq(AuthenticationService::AuthenticationError)
    end

    it "UserExistsError inherits from AuthenticationError" do
      expect(AuthenticationService::UserExistsError.superclass).to eq(AuthenticationService::AuthenticationError)
    end

    it "AuthenticationError inherits from StandardError" do
      expect(AuthenticationService::AuthenticationError.superclass).to eq(StandardError)
    end
  end
end
