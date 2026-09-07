require "rails_helper"

RSpec.describe "Api::V1::Admin::Products Edge Cases", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:customer) { create(:user) }
  let(:admin_token) { create(:auth_token, user: admin).token }
  let(:customer_token) { create(:auth_token, user: customer).token }

  describe "GET /api/v1/admin/products" do
    context "with no products" do
      it "returns empty array" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
        expect(json["meta"]["total_count"]).to eq(0)
      end
    end

    context "pagination edge cases" do
      before { create_list(:product, 25) }

      it "returns first page by default" do
        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["meta"]["page"]).to eq(1)
      end

      it "returns empty array for page beyond total" do
        get "/api/v1/admin/products", params: { page: 100 }, headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end
    end

    context "filtering" do
      it "filters by active status true" do
        create(:product, active: true)
        create(:product, :inactive)

        get "/api/v1/admin/products", params: { active: "true" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| p["active"] }).to be true
      end

      it "filters by active status false" do
        create(:product, active: true)
        create(:product, :inactive)

        get "/api/v1/admin/products", params: { active: "false" }, headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| !p["active"] }).to be true
      end

      it "shows all products when no active filter" do
        create(:product, active: true)
        create(:product, :inactive)

        get "/api/v1/admin/products", headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(2)
      end
    end
  end

  describe "POST /api/v1/admin/products" do
    context "with edge case params" do
      it "creates product with zero price" do
        post "/api/v1/admin/products",
             params: { name: "Free Item", price_cents: 0, sku: "FREE-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["product"]["price_cents"]).to eq(0)
      end

      it "creates product with zero stock" do
        post "/api/v1/admin/products",
             params: { name: "Out of Stock", price_cents: 1000, stock_quantity: 0, sku: "OOS-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:created)
      end

      it "creates product without description" do
        post "/api/v1/admin/products",
             params: { name: "No Description", price_cents: 1000, sku: "NODESC-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:created)
      end

      it "rejects product without name" do
        post "/api/v1/admin/products",
             params: { price_cents: 1000, sku: "NONAME-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product without SKU" do
        post "/api/v1/admin/products",
             params: { name: "No SKU", price_cents: 1000 },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product with duplicate SKU" do
        create(:product, sku: "DUPLICATE-001")

        post "/api/v1/admin/products",
             params: { name: "Duplicate", price_cents: 1000, sku: "DUPLICATE-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product with negative price" do
        post "/api/v1/admin/products",
             params: { name: "Negative Price", price_cents: -100, sku: "NEG-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product with negative stock" do
        post "/api/v1/admin/products",
             params: { name: "Negative Stock", price_cents: 1000, stock_quantity: -1, sku: "NEGS-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product with too long name" do
        post "/api/v1/admin/products",
             params: { name: "A" * 256, price_cents: 1000, sku: "LONG-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects product with too long SKU" do
        post "/api/v1/admin/products",
             params: { name: "Long SKU", price_cents: 1000, sku: "A" * 51 },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "response format" do
      it "returns created product with all fields" do
        post "/api/v1/admin/products",
             params: { name: "Test Product", description: "Test", price_cents: 1999, sku: "TEST-001" },
             headers: { "Authorization" => "Bearer #{admin_token}" }

        json = JSON.parse(response.body)
        product = json["product"]

        expect(product["id"]).to be_present
        expect(product["name"]).to eq("Test Product")
        expect(product["description"]).to eq("Test")
        expect(product["price_cents"]).to eq(1999)
        expect(product["sku"]).to eq("TEST-001")
        expect(product["created_at"]).to be_present
        expect(product["updated_at"]).to be_present
      end
    end
  end

  describe "PATCH /api/v1/admin/products/:id" do
    let!(:product) { create(:product, name: "Original", price_cents: 1000) }

    context "partial updates" do
      it "updates only name" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { name: "Updated" },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["name"]).to eq("Updated")
        expect(json["product"]["price_cents"]).to eq(1000) # unchanged
      end

      it "updates only price" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { price_cents: 2000 },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["name"]).to eq("Original") # unchanged
        expect(json["product"]["price_cents"]).to eq(2000)
      end

      it "updates only stock" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { stock_quantity: 50 },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["stock_quantity"]).to eq(50)
      end

      it "can deactivate product" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { active: false },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["active"]).to be false
      end

      it "can reactivate product" do
        product.update!(active: false)

        patch "/api/v1/admin/products/#{product.id}",
              params: { active: true },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["product"]["active"]).to be true
      end
    end

    context "validation on update" do
      it "rejects update with negative price" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { price_cents: -100 },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects update with duplicate SKU" do
        other_product = create(:product, sku: "OTHER-001")

        patch "/api/v1/admin/products/#{product.id}",
              params: { sku: "OTHER-001" },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "allows keeping same SKU" do
        patch "/api/v1/admin/products/#{product.id}",
              params: { sku: product.sku },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "non-existent product" do
      it "returns 404 for non-existent product" do
        patch "/api/v1/admin/products/999999",
              params: { name: "Test" },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for deleted product" do
        product.destroy

        patch "/api/v1/admin/products/#{product.id}",
              params: { name: "Test" },
              headers: { "Authorization" => "Bearer #{admin_token}" }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/admin/products/:id" do
    it "deletes existing product" do
      product = create(:product)

      expect {
        delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }
      }.to change(Product, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent product" do
      delete "/api/v1/admin/products/999999", headers: { "Authorization" => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when deleting same product twice" do
      product = create(:product)

      delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:no_content)

      delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:not_found)
    end

    it "customer cannot delete product" do
      product = create(:product)

      delete "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{customer_token}" }

      expect(response).to have_http_status(:forbidden)
      expect(Product.exists?(product.id)).to be true
    end
  end

  describe "GET /api/v1/admin/products/:id" do
    it "returns inactive product" do
      product = create(:product, :inactive)

      get "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["product"]["active"]).to be false
    end

    it "returns product with all fields" do
      product = create(:product)

      get "/api/v1/admin/products/#{product.id}", headers: { "Authorization" => "Bearer #{admin_token}" }

      json = JSON.parse(response.body)
      product_json = json["product"]

      expect(product_json).to include(
        "id", "name", "description", "price_cents", "price_formatted",
        "currency", "stock_quantity", "active", "available", "sku",
        "created_at", "updated_at"
      )
    end
  end
end
