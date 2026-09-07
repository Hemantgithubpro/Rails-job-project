require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  describe "GET /api/v1/products" do
    let!(:products) { create_list(:product, 5, :in_stock) }
    let!(:inactive_product) { create(:product, :inactive) }

    it "returns active products" do
      get "/api/v1/products"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["products"].length).to eq(5)
    end

    it "does not include inactive products" do
      get "/api/v1/products"

      json = JSON.parse(response.body)
      product_ids = json["products"].map { |p| p["id"] }
      expect(product_ids).not_to include(inactive_product.id)
    end

    it "returns product details" do
      get "/api/v1/products"

      json = JSON.parse(response.body)
      product = json["products"].first
      expect(product).to have_key("id")
      expect(product).to have_key("name")
      expect(product).to have_key("description")
      expect(product).to have_key("price_cents")
      expect(product).to have_key("price_formatted")
      expect(product).to have_key("currency")
      expect(product).to have_key("stock_quantity")
      expect(product).to have_key("available")
      expect(product).to have_key("sku")
      expect(product).to have_key("created_at")
      expect(product).to have_key("updated_at")
    end

    it "includes pagination metadata" do
      get "/api/v1/products"

      json = JSON.parse(response.body)
      expect(json["meta"]).to have_key("total_count")
      expect(json["meta"]).to have_key("page")
      expect(json["meta"]).to have_key("per_page")
      expect(json["meta"]).to have_key("total_pages")
    end

    context "with search" do
      it "filters products by name" do
        create(:product, name: "Special Widget")
        create(:product, name: "Regular Item")

        get "/api/v1/products", params: { q: "Widget" }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
        expect(json["products"].first["name"]).to eq("Special Widget")
      end

      it "is case insensitive" do
        create(:product, name: "WIDGET")

        get "/api/v1/products", params: { q: "widget" }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(1)
      end
    end

    context "with price filter" do
      it "filters by minimum price" do
        create(:product, price_cents: 1000)
        create(:product, price_cents: 5000)

        get "/api/v1/products", params: { min_price_cents: 2000 }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| p["price_cents"] >= 2000 }).to be true
      end

      it "filters by maximum price" do
        create(:product, price_cents: 1000)
        create(:product, price_cents: 5000)

        get "/api/v1/products", params: { max_price_cents: 2000 }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| p["price_cents"] <= 2000 }).to be true
      end

      it "filters by price range" do
        in_range = create(:product, price_cents: 5000)
        below_range = create(:product, price_cents: 1000)
        above_range = create(:product, price_cents: 10000)

        get "/api/v1/products", params: { min_price_cents: 2000, max_price_cents: 6000 }

        json = JSON.parse(response.body)
        product_ids = json["products"].map { |p| p["id"] }
        expect(product_ids).to include(in_range.id)
        expect(product_ids).not_to include(below_range.id)
        expect(product_ids).not_to include(above_range.id)
      end
    end

    context "with stock filter" do
      it "filters to in-stock products only" do
        create(:product, :in_stock)
        create(:product, :out_of_stock)

        get "/api/v1/products", params: { in_stock: "true" }

        json = JSON.parse(response.body)
        expect(json["products"].all? { |p| p["stock_quantity"] > 0 }).to be true
      end
    end

    context "with sorting" do
      it "sorts by price ascending" do
        create(:product, price_cents: 5000)
        create(:product, price_cents: 1000)

        get "/api/v1/products", params: { sort: "price_asc" }

        json = JSON.parse(response.body)
        prices = json["products"].map { |p| p["price_cents"] }
        expect(prices).to eq(prices.sort)
      end

      it "sorts by price descending" do
        create(:product, price_cents: 1000)
        create(:product, price_cents: 5000)

        get "/api/v1/products", params: { sort: "price_desc" }

        json = JSON.parse(response.body)
        prices = json["products"].map { |p| p["price_cents"] }
        expect(prices).to eq(prices.sort.reverse)
      end

      it "sorts by name" do
        create(:product, name: "Banana")
        create(:product, name: "Apple")

        get "/api/v1/products", params: { sort: "name" }

        json = JSON.parse(response.body)
        names = json["products"].map { |p| p["name"] }
        expect(names).to eq(names.sort)
      end
    end

    context "with pagination" do
      it "paginates results" do
        create_list(:product, 25)

        get "/api/v1/products", params: { page: 1, per_page: 10 }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(10)
        expect(json["meta"]["total_pages"]).to eq(3)
      end

      it "returns second page" do
        create_list(:product, 25)

        get "/api/v1/products", params: { page: 2, per_page: 10 }

        json = JSON.parse(response.body)
        expect(json["products"].length).to eq(10)
        expect(json["meta"]["page"]).to eq(2)
      end

      it "caps per_page at 100" do
        get "/api/v1/products", params: { per_page: 200 }

        json = JSON.parse(response.body)
        expect(json["meta"]["per_page"]).to eq(100)
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    let!(:product) { create(:product) }

    it "returns the product" do
      get "/api/v1/products/#{product.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["product"]["id"]).to eq(product.id)
      expect(json["product"]["name"]).to eq(product.name)
    end

    it "returns 404 for non-existent product" do
      get "/api/v1/products/999999"

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]["code"]).to eq("not_found")
    end

    it "returns 404 for inactive product" do
      inactive = create(:product, :inactive)

      get "/api/v1/products/#{inactive.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
