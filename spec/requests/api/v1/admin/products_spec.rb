require "rails_helper"

RSpec.describe "Api::V1::Admin::Products", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:customer) { create(:user) }
  let(:admin_token) { create(:auth_token, user: admin).token }
  let(:customer_token) { create(:auth_token, user: customer).token }

  describe "GET /api/v1/admin/products" do
    let!(:products) { create_list(:product, 5) }
    let!(:inactive_product) { create(:product, :inactive) }

    context "as admin" do
      it "returns all products including inactive" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(6)
      end

      it "includes inactive products" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        product_ids = json["products"].map { |p| p["id"] }
        expect(product_ids).to include(inactive_product.id)
      end

      it "filters by active status" do
        get "/api/v1/admin/products", params: { active: "true" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| p["active"] }).to be true
      end

      it "includes pagination metadata" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["meta"]).to have_key("total_count")
        expect(json["meta"]).to have_key("page")
        expect(json["meta"]).to have_key("per_page")
        expect(json["meta"]).to have_key("total_pages")
      end
    end

    context "as customer" do
      it "returns 403 forbidden" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{customer_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("forbidden")
      end
    end

    context "without authentication" do
      it "returns 401 unauthorized" do
        get "/api/v1/admin/products"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/admin/products/:id" do
    let!(:product) { create(:product) }

    context "as admin" do
      it "returns the product" do
        get "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["id"]).to eq(product.id)
      end

      it "returns inactive products" do
        inactive = create(:product, :inactive)

        get "/api/v1/admin/products/#{inactive.id}", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
      end

      it "returns 404 for non-existent product" do
        get "/api/v1/admin/products/999999", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("not_found")
      end
    end

    context "as customer" do
      it "returns 403 forbidden" do
        get "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{customer_token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /api/v1/admin/products" do
    let(:valid_params) do
      {
        name: "New Product",
        description: "A great product",
        price_cents: 1999,
        currency: "USD",
        stock_quantity: 10,
        sku: "NEW-001"
      }
    end

    context "as admin" do
      it "creates a new product" do
        expect {
          post "/api/v1/admin/products", params: valid_params, headers: { "Authorization" => "Bearer #{admin_token}" }
        }.to change(Product, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns the created product" do
        post "/api/v1/admin/products", params: valid_params, headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["product"]["name"]).to eq("New Product")
        expect(json["product"]["price_cents"]).to eq(1999)
        expect(json["product"]["sku"]).to eq("NEW-001")
      end

      it "returns 422 for invalid params" do
        post "/api/v1/admin/products", params: { name: "" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("validation_failed")
      end

      it "returns 422 for duplicate SKU" do
        create(:product, sku: "NEW-001")

        post "/api/v1/admin/products", params: valid_params, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns 422 for negative price" do
        post "/api/v1/admin/products", params: valid_params.merge(price_cents: -1), headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as customer" do
      it "returns 403 forbidden" do
        post "/api/v1/admin/products", params: valid_params, headers: { "Authorization" => "Bearer #{customer_token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/admin/products/:id" do
    let!(:product) { create(:product, name: "Old Name", price_cents: 1000) }

    context "as admin" do
      it "updates the product" do
        patch "/api/v1/admin/products/#{product.id}", params: { name: "New Name" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["name"]).to eq("New Name")
      end

      it "updates price" do
        patch "/api/v1/admin/products/#{product.id}", params: { price_cents: 2000 }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["price_cents"]).to eq(2000)
      end

      it "can deactivate product" do
        patch "/api/v1/admin/products/#{product.id}", params: { active: false }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["active"]).to be false
      end

      it "returns 404 for non-existent product" do
        patch "/api/v1/admin/products/999999", params: { name: "Test" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 422 for invalid params" do
        patch "/api/v1/admin/products/#{product.id}", params: { price_cents: -1 }, headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as customer" do
      it "returns 403 forbidden" do
        patch "/api/v1/admin/products/#{product.id}", params: { name: "Hacked" }, headers: { "Authorization" => "Bearer #{customer_token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v1/admin/products/:id" do
    let!(:product) { create(:product) }

    context "as admin" do
      it "deletes the product" do
        expect {
          delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }
        }.to change(Product, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it "returns 404 for non-existent product" do
        delete "/api/v1/admin/products/999999", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as customer" do
      it "returns 403 forbidden" do
        delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{customer_token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
