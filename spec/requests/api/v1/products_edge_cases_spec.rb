require "rails_helper"

RSpec.describe "Api::V1::Products Edge Cases", type: :request do
  describe "GET /api/v1/products" do
    context "with no products" do
      it "returns empty array" do
        get "/api/v1/products"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
        expect(json["meta"]["total_count"]).to eq(0)
      end
    end

    context "with only inactive products" do
      it "returns empty array" do
        create_list(:product, 3, :inactive)

        get "/api/v1/products"

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end
    end

    context "pagination edge cases" do
      before { create_list(:product, 25) }

      it "returns first page by default" do
        get "/api/v1/products"

        json = JSON.parse(response.body)
        expect(json["meta"]["page"]).to eq(1)
        expect(json["products"].length).to eq(20) # default per_page
      end

      it "returns empty array for page beyond total" do
        get "/api/v1/products", params: { page: 100 }

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end

      it "handles page 0 gracefully" do
        get "/api/v1/products", params: { page: 0 }

        # Should either return first page or handle gracefully
        expect(response).to have_http_status(:ok)
      end

      it "handles negative page gracefully" do
        get "/api/v1/products", params: { page: -1 }

        expect(response).to have_http_status(:ok)
      end

      it "handles string page number" do
        get "/api/v1/products", params: { page: "abc" }

        expect(response).to have_http_status(:ok)
      end

      it "caps per_page at 100" do
        get "/api/v1/products", params: { per_page: 500 }

        json = JSON.parse(response.body)
        expect(json["meta"]["per_page"]).to eq(100)
      end

      it "handles zero per_page" do
        get "/api/v1/products", params: { per_page: 0 }

        # Should use default or handle gracefully
        expect(response).to have_http_status(:ok)
      end
    end

    context "sorting edge cases" do
      it "defaults to name sort for invalid sort parameter" do
        create(:product, name: "Banana")
        create(:product, name: "Apple")

        get "/api/v1/products", params: { sort: "invalid" }

        json = JSON.parse(response.body)
        names = json["products"].map { |p| p["name"] }
        expect(names).to eq(names.sort)
      end

      it "handles products with same price in price sort" do
        create(:product, price_cents: 1000, name: "A")
        create(:product, price_cents: 1000, name: "B")

        get "/api/v1/products", params: { sort: "price_asc" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(2)
      end

      it "handles products with same name in name sort" do
        create(:product, name: "Same Name", sku: "SKU-001")
        create(:product, name: "Same Name", sku: "SKU-002")

        get "/api/v1/products", params: { sort: "name" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(2)
      end
    end

    context "filtering edge cases" do
      it "returns empty for search with no matches" do
        create(:product, name: "Apple")

        get "/api/v1/products", params: { q: "Orange" }

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end

      it "handles empty search query" do
        create(:product, name: "Apple")

        get "/api/v1/products", params: { q: "" }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
      end

      it "handles search with special characters" do
        create(:product, name: "Product (Special)")

        get "/api/v1/products", params: { q: "(Special)" }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
      end

      it "handles search with SQL injection attempt" do
        create(:product, name: "Apple")

        get "/api/v1/products", params: { q: "'; DROP TABLE products; --" }

        # Should not raise error and products table should still exist
        expect(response).to have_http_status(:ok)
        expect(Product.count).to be >= 0
      end

      it "handles negative min_price" do
        create(:product, price_cents: 1000)

        get "/api/v1/products", params: { min_price_cents: -100 }

        expect(response).to have_http_status(:ok)
      end

      it "handles negative max_price" do
        create(:product, price_cents: 1000)

        get "/api/v1/products", params: { max_price_cents: -100 }

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end

      it "handles min_price greater than max_price" do
        create(:product, price_cents: 5000)

        get "/api/v1/products", params: { min_price_cents: 10000, max_price_cents: 1000 }

        json = JSON.parse(response.body)
        expect(json["products"]).to eq([])
      end

      it "handles string price values" do
        get "/api/v1/products", params: { min_price_cents: "abc" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "combined filters" do
      it "applies multiple filters together" do
        create(:product, name: "Red Apple", price_cents: 1000, stock_quantity: 10)
        create(:product, name: "Green Apple", price_cents: 2000, stock_quantity: 5)
        create(:product, name: "Banana", price_cents: 500, stock_quantity: 0)

        get "/api/v1/products", params: {
          q: "Apple",
          min_price_cents: 500,
          max_price_cents: 1500,
          in_stock: "true"
        }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
        expect(json["products"].first["name"]).to eq("Red Apple")
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    it "returns 404 for non-integer ID" do
      get "/api/v1/products/abc"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for very large ID" do
      get "/api/v1/products/999999999999999999"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for negative ID" do
      get "/api/v1/products/-1"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for zero ID" do
      get "/api/v1/products/0"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for deleted product" do
      product = create(:product)
      product.destroy

      get "/api/v1/products/#{product.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for deactivated product" do
      product = create(:product, :inactive)

      get "/api/v1/products/#{product.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "response format" do
    it "returns correct product JSON structure" do
      product = create(:product, name: "Test Product", price_cents: 1999)

      get "/api/v1/products/#{product.id}"

      json = JSON.parse(response.body)
      product_json = json["product"]

      expect(product_json).to include(
        "id",
        "name",
        "description",
        "price_cents",
        "price_formatted",
        "currency",
        "stock_quantity",
        "available",
        "sku",
        "created_at",
        "updated_at"
      )
    end

    it "does not include internal fields" do
      product = create(:product)

      get "/api/v1/products/#{product.id}"

      json = JSON.parse(response.body)
      product_json = json["product"]

      expect(product_json).not_to have_key("_id")
      expect(product_json).not_to have_key("lock_version")
    end

    it "returns ISO 8601 timestamps" do
      product = create(:product)

      get "/api/v1/products/#{product.id}"

      json = JSON.parse(response.body)
      product_json = json["product"]

      # Verify ISO 8601 format
      expect(product_json["created_at"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(product_json["updated_at"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end
end
