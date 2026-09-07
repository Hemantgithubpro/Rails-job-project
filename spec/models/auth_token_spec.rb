require "rails_helper"

RSpec.describe AuthToken, type: :model do
  describe "validations" do
    it "validates uniqueness of token" do
      existing = create(:auth_token)
      auth_token = build(:auth_token, token: existing.token)
      expect(auth_token).not_to be_valid
      expect(auth_token.errors[:token]).to include("has already been taken")
    end

    it "requires expires_at" do
      auth_token = AuthToken.new(token: "test", expires_at: nil)
      # Disable callbacks for this test
      AuthToken.skip_callback(:validation, :before, :set_expiration)
      expect(auth_token).not_to be_valid
      expect(auth_token.errors[:expires_at]).to include("can't be blank")
      AuthToken.set_callback(:validation, :before, :set_expiration)
    end

    it "requires user" do
      auth_token = AuthToken.new(token: "test", expires_at: 1.day.from_now, user: nil)
      expect(auth_token).not_to be_valid
      expect(auth_token.errors[:user]).to include("must exist")
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "callbacks" do
    it "generates a token before creation" do
      auth_token = create(:auth_token, token: nil)
      expect(auth_token.token).to be_present
      expect(auth_token.token.length).to eq(64) # 32 bytes hex encoded
    end

    it "generates unique tokens" do
      token1 = create(:auth_token).token
      token2 = create(:auth_token).token
      expect(token1).not_to eq(token2)
    end

    it "sets expiration before creation" do
      auth_token = create(:auth_token, expires_at: nil)
      expect(auth_token.expires_at).to be_present
      expect(auth_token.expires_at).to be > Time.current
    end

    it "sets expiration to 7 days from now by default" do
      auth_token = create(:auth_token)
      expected_expiration = 7.days.from_now
      expect(auth_token.expires_at).to be_within(1.minute).of(expected_expiration)
    end

    it "preserves custom expiration if provided" do
      custom_expiration = 1.day.from_now
      auth_token = create(:auth_token, expires_at: custom_expiration)
      expect(auth_token.expires_at).to be_within(1.second).of(custom_expiration)
    end
  end

  describe "scopes" do
    let!(:active_token) { create(:auth_token) }
    let!(:expired_token) { create(:auth_token, :expired) }
    let!(:revoked_token) { create(:auth_token, :revoked) }

    it ".active returns only active tokens" do
      expect(AuthToken.active).to include(active_token)
      expect(AuthToken.active).not_to include(expired_token)
      expect(AuthToken.active).not_to include(revoked_token)
    end

    it ".expired returns only expired tokens" do
      expect(AuthToken.expired).to include(expired_token)
      expect(AuthToken.expired).not_to include(active_token)
    end

    it ".revoked returns only revoked tokens" do
      expect(AuthToken.revoked).to include(revoked_token)
      expect(AuthToken.revoked).not_to include(active_token)
    end
  end

  describe "#active?" do
    it "returns true for non-expired, non-revoked token" do
      auth_token = build(:auth_token)
      expect(auth_token.active?).to be true
    end

    it "returns false for expired token" do
      auth_token = build(:auth_token, :expired)
      expect(auth_token.active?).to be false
    end

    it "returns false for revoked token" do
      auth_token = build(:auth_token, :revoked)
      expect(auth_token.active?).to be false
    end

    it "returns false for token expiring now" do
      auth_token = build(:auth_token, expires_at: Time.current)
      expect(auth_token.active?).to be false
    end

    it "returns true for token expiring in the future" do
      auth_token = build(:auth_token, expires_at: 1.second.from_now)
      expect(auth_token.active?).to be true
    end
  end

  describe "#expired?" do
    it "returns true for expired token" do
      auth_token = build(:auth_token, :expired)
      expect(auth_token.expired?).to be true
    end

    it "returns false for non-expired token" do
      auth_token = build(:auth_token)
      expect(auth_token.expired?).to be false
    end

    it "returns true for token expiring in the past" do
      auth_token = build(:auth_token, expires_at: 1.hour.ago)
      expect(auth_token.expired?).to be true
    end

    it "returns false for token expiring in the future" do
      auth_token = build(:auth_token, expires_at: 1.hour.from_now)
      expect(auth_token.expired?).to be false
    end
  end

  describe "#revoked?" do
    it "returns true for revoked token" do
      auth_token = build(:auth_token, :revoked)
      expect(auth_token.revoked?).to be true
    end

    it "returns false for non-revoked token" do
      auth_token = build(:auth_token)
      expect(auth_token.revoked?).to be false
    end

    it "returns false for token with nil revoked_at" do
      auth_token = build(:auth_token, revoked_at: nil)
      expect(auth_token.revoked?).to be false
    end
  end

  describe "#revoke!" do
    it "sets revoked_at timestamp" do
      auth_token = create(:auth_token)
      expect(auth_token.revoked_at).to be_nil

      auth_token.revoke!
      expect(auth_token.revoked_at).to be_present
    end

    it "sets revoked_at to approximately current time" do
      auth_token = create(:auth_token)
      before_revoke = Time.current

      auth_token.revoke!

      after_revoke = Time.current
      expect(auth_token.revoked_at).to be >= before_revoke
      expect(auth_token.revoked_at).to be <= after_revoke
    end

    it "makes token inactive" do
      auth_token = create(:auth_token)
      expect(auth_token.active?).to be true

      auth_token.revoke!
      expect(auth_token.active?).to be false
    end

    it "makes token show as revoked" do
      auth_token = create(:auth_token)
      auth_token.revoke!
      expect(auth_token.revoked?).to be true
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:auth_token)).to be_valid
    end

    it "has a valid expired trait" do
      token = build(:auth_token, :expired)
      expect(token).to be_valid
      expect(token.expired?).to be true
    end

    it "has a valid revoked trait" do
      token = build(:auth_token, :revoked)
      expect(token).to be_valid
      expect(token.revoked?).to be true
    end
  end

  describe "token security" do
    it "generates tokens of sufficient length" do
      auth_token = create(:auth_token)
      expect(auth_token.token.length).to be >= 32
    end

    it "generates hexadecimal tokens" do
      auth_token = create(:auth_token)
      expect(auth_token.token).to match(/\A[a-f0-9]+\z/)
    end

    it "generates unpredictable tokens" do
      tokens = 100.times.map { create(:auth_token).token }
      expect(tokens.uniq.length).to eq(100)
    end
  end
end
