require "rails_helper"

RSpec.describe "Admin Authorization", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:customer) { create(:user) }
  let(:admin_token) { create(:auth_token, user: admin).token }
  let(:customer_token) { create(:auth_token, user: customer).token }
  let(:expired_admin_token) { create(:auth_token, :expired, user: admin).token }
  let(:revoked_admin_token) { create(:auth_token, :revoked, user: admin).token }

  describe "Authorization header variations" do
    it "rejects admin request without Authorization header" do
      get "/api/v1/admin/products"

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("unauthorized")
    end

    it "rejects admin request with empty Authorization header" do
      get "/api/v1/admin/products", headers: { "Authorization" => "" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin request with malformed Authorization header" do
      get "/api/v1/admin/products", headers: { "Authorization" => "NotBearer token123" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin request with Basic auth" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Basic dXNlcjpwYXNz" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin request with invalid token format" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer " }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin request with non-existent token" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer nonexistent-token-12345" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Token state handling" do
    it "rejects expired admin token" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{expired_admin_token}" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("unauthorized")
    end

    it "rejects revoked admin token" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{revoked_admin_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects admin token for deleted user" do
      token = admin_token
      admin.destroy

      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Role-based access control" do
    it "allows admin to access admin endpoints" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "forbids customer from admin endpoints" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{customer_token}" }

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("forbidden")
    end

    it "allows customer to access public endpoints" do
      get "/api/v1/products", headers: { "Authorization" => "Bearer #{customer_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "allows admin to access public endpoints" do
      get "/api/v1/products", headers: { "Authorization" => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "allows unauthenticated access to public endpoints" do
      get "/api/v1/products"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "Case sensitivity in Authorization header" do
    it "accepts lowercase bearer" do
      get "/api/v1/admin/products", headers: { "Authorization" => "bearer #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "accepts mixed case Bearer" do
      get "/api/v1/admin/products", headers: { "Authorization" => "BEARER #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end

    it "accepts multiple spaces before token" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer   #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "Error response format" do
    it "returns proper error format for unauthorized" do
      get "/api/v1/admin/products"

      json = JSON.parse(response.body)
      expect(json).to have_key("error")
      expect(json["error"]).to have_key("code")
      expect(json["error"]).to have_key("message")
      expect(json["error"]["code"]).to eq("unauthorized")
    end

    it "returns proper error format for forbidden" do
      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{customer_token}" }

      json = JSON.parse(response.body)
      expect(json).to have_key("error")
      expect(json["error"]).to have_key("code")
      expect(json["error"]).to have_key("message")
      expect(json["error"]["code"]).to eq("forbidden")
    end
  end

  describe "Multiple requests with same token" do
    it "allows multiple admin requests with same token" do
      3.times do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Token after role change" do
    it "token still works after user role changes from admin to customer" do
      token = admin_token

      # Change role to customer
      admin.update!(role: "customer")

      get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{token}" }

      # Token should now be forbidden since user is no longer admin
      expect(response).to have_http_status(:forbidden)
    end
  end
end
