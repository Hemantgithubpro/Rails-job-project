require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(%w[customer admin]) }
    it { should validate_length_of(:password).is_at_least(8) }

    context "email validation" do
      it "is valid with valid attributes" do
        user = build(:user)
        expect(user).to be_valid
      end

      it "is invalid without an email" do
        user = build(:user, email: nil)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it "is invalid with a duplicate email" do
        create(:user, email: "test@example.com")
        user = build(:user, email: "test@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end

      it "is invalid with a duplicate email regardless of case" do
        create(:user, email: "test@example.com")
        user = build(:user, email: "TEST@example.com")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("has already been taken")
      end

      it "is invalid with a duplicate email with whitespace" do
        create(:user, email: "test@example.com")
        user = build(:user, email: "  test@example.com  ")
        expect(user).not_to be_valid
      end

      it "is invalid with a malformed email" do
        user = build(:user, email: "not-an-email")
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("must be a valid email address")
      end

      it "is invalid without @" do
        user = build(:user, email: "testexample.com")
        expect(user).not_to be_valid
      end

      it "is invalid without domain" do
        user = build(:user, email: "test@")
        expect(user).not_to be_valid
      end

      it "is invalid with spaces in email" do
        user = build(:user, email: "test @example.com")
        expect(user).not_to be_valid
      end

      it "is valid with plus addressing" do
        user = build(:user, email: "test+tag@example.com")
        expect(user).to be_valid
      end

      it "is valid with subdomain" do
        user = build(:user, email: "test@mail.example.com")
        expect(user).to be_valid
      end

      it "is valid with numbers in domain" do
        user = build(:user, email: "test@example123.com")
        expect(user).to be_valid
      end
    end

    context "password validation" do
      it "is invalid with a short password" do
        user = build(:user, password: "short")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "is invalid with 7 character password" do
        user = build(:user, password: "1234567")
        expect(user).not_to be_valid
      end

      it "is valid with 8 character password" do
        user = build(:user, password: "12345678")
        expect(user).to be_valid
      end

      it "is valid with 72 character password (bcrypt limit)" do
        user = build(:user, password: "a" * 72)
        expect(user).to be_valid
      end

      it "is valid with complex password" do
        user = build(:user, password: "P@ssw0rd!#$%")
        expect(user).to be_valid
      end

      it "does not require password on update if not changing" do
        user = create(:user)
        user.email = "newemail@example.com"
        expect(user).to be_valid
      end
    end

    context "role validation" do
      it "is valid with customer role" do
        user = build(:user, role: "customer")
        expect(user).to be_valid
      end

      it "is valid with admin role" do
        user = build(:user, role: "admin")
        expect(user).to be_valid
      end

      it "is invalid with invalid role" do
        user = build(:user, role: "superadmin")
        expect(user).not_to be_valid
        expect(user.errors[:role]).to include("is not included in the list")
      end

      it "is invalid with empty role" do
        user = build(:user, role: "")
        expect(user).not_to be_valid
      end

      it "defaults to customer role" do
        user = User.new(email: "test@example.com", password: "password123")
        expect(user.role).to eq("customer")
      end
    end
  end

  describe "associations" do
    it { should have_many(:auth_tokens).dependent(:destroy) }

    it "destroys associated auth_tokens when destroyed" do
      user = create(:user)
      create_list(:auth_token, 3, user: user)

      expect { user.destroy }.to change(AuthToken, :count).by(-3)
    end
  end

  describe "callbacks" do
    it "normalizes email before validation" do
      user = build(:user, email: "  TEST@EXAMPLE.COM  ")
      user.valid?
      expect(user.email).to eq("test@example.com")
    end

    it "converts email to lowercase" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      expect(user.email).to eq("test@example.com")
    end

    it "trims whitespace from email" do
      user = create(:user, email: "  test@example.com  ")
      expect(user.email).to eq("test@example.com")
    end

    it "handles nil email gracefully" do
      user = User.new(email: nil, password: "password123")
      expect { user.valid? }.not_to raise_error
    end
  end

  describe "scopes" do
    let!(:customer1) { create(:user, role: "customer") }
    let!(:customer2) { create(:user, role: "customer") }
    let!(:admin1) { create(:user, :admin) }
    let!(:admin2) { create(:user, :admin) }

    it ".customers returns only customers" do
      customers = User.customers
      expect(customers).to include(customer1, customer2)
      expect(customers).not_to include(admin1, admin2)
    end

    it ".admins returns only admins" do
      admins = User.admins
      expect(admins).to include(admin1, admin2)
      expect(admins).not_to include(customer1, customer2)
    end
  end

  describe "#customer?" do
    it "returns true for customer role" do
      user = build(:user, role: "customer")
      expect(user.customer?).to be true
    end

    it "returns false for admin role" do
      user = build(:user, role: "admin")
      expect(user.customer?).to be false
    end
  end

  describe "#admin?" do
    it "returns true for admin role" do
      user = build(:user, role: "admin")
      expect(user.admin?).to be true
    end

    it "returns false for customer role" do
      user = build(:user, role: "customer")
      expect(user.admin?).to be false
    end
  end

  describe "has_secure_password" do
    it "authenticates with correct password" do
      user = create(:user, password: "password123")
      expect(user.authenticate("password123")).to eq(user)
    end

    it "does not authenticate with incorrect password" do
      user = create(:user, password: "password123")
      expect(user.authenticate("wrongpassword")).to be false
    end

    it "does not authenticate with empty password" do
      user = create(:user, password: "password123")
      expect(user.authenticate("")).to be false
    end

    it "does not authenticate with nil password" do
      user = create(:user, password: "password123")
      expect(user.authenticate(nil)).to be false
    end

    it "stores password_digest" do
      user = create(:user, password: "password123")
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("password123")
    end

    it "password_digest is set by has_secure_password" do
      user = User.new(email: "test@example.com", password: "password123")
      user.save!
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("password123")
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:user)).to be_valid
    end

    it "has a valid admin factory" do
      admin = build(:user, :admin)
      expect(admin).to be_valid
      expect(admin.admin?).to be true
    end

    it "creates unique emails" do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.email).not_to eq(user2.email)
    end
  end
end
