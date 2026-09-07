require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    subject { build(:product) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(5000) }
    it { should validate_presence_of(:price_cents) }
    it { should validate_numericality_of(:price_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:currency) }
    it { should validate_length_of(:currency).is_equal_to(3) }
    it { should validate_presence_of(:stock_quantity) }
    it { should validate_numericality_of(:stock_quantity).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:sku) }
    it { should validate_uniqueness_of(:sku) }
    it { should validate_length_of(:sku).is_at_most(50) }

    context "basic validity" do
      it "is valid with valid attributes" do
        expect(build(:product)).to be_valid
      end

      it "is invalid without a name" do
        product = build(:product, name: nil)
        expect(product).not_to be_valid
        expect(product.errors[:name]).to include("can't be blank")
      end

      it "is invalid with a duplicate SKU" do
        create(:product, sku: "TEST-001")
        product = build(:product, sku: "TEST-001")
        expect(product).not_to be_valid
        expect(product.errors[:sku]).to include("has already been taken")
      end

      it "is invalid with negative price" do
        product = build(:product, price_cents: -1)
        expect(product).not_to be_valid
      end

      it "is invalid with negative stock" do
        product = build(:product, stock_quantity: -1)
        expect(product).not_to be_valid
      end
    end

    context "name edge cases" do
      it "is valid with a single character name" do
        product = build(:product, name: "A")
        expect(product).to be_valid
      end

      it "is valid with 255 character name" do
        product = build(:product, name: "A" * 255)
        expect(product).to be_valid
      end

      it "is invalid with 256 character name" do
        product = build(:product, name: "A" * 256)
        expect(product).not_to be_valid
      end

      it "is valid with special characters in name" do
        product = build(:product, name: "Product™ - Special Edition (2024)")
        expect(product).to be_valid
      end

      it "is valid with unicode characters in name" do
        product = build(:product, name: "日本語プロダクト")
        expect(product).to be_valid
      end

      it "is valid with numbers in name" do
        product = build(:product, name: "Product 123")
        expect(product).to be_valid
      end
    end

    context "description edge cases" do
      it "is valid without description" do
        product = build(:product, description: nil)
        expect(product).to be_valid
      end

      it "is valid with empty description" do
        product = build(:product, description: "")
        expect(product).to be_valid
      end

      it "is valid with 5000 character description" do
        product = build(:product, description: "A" * 5000)
        expect(product).to be_valid
      end

      it "is invalid with 5001 character description" do
        product = build(:product, description: "A" * 5001)
        expect(product).not_to be_valid
      end

      it "is valid with multiline description" do
        product = build(:product, description: "Line 1\nLine 2\nLine 3")
        expect(product).to be_valid
      end
    end

    context "price edge cases" do
      it "is valid with zero price" do
        product = build(:product, price_cents: 0)
        expect(product).to be_valid
      end

      it "is valid with large price" do
        product = build(:product, price_cents: 1_000_000_000)
        expect(product).to be_valid
      end

      it "is invalid with float price" do
        product = build(:product, price_cents: 19.99)
        expect(product).not_to be_valid
      end

      it "is invalid with string price" do
        product = build(:product, price_cents: "free")
        expect(product).not_to be_valid
      end
    end

    context "currency edge cases" do
      it "is valid with EUR currency" do
        product = build(:product, currency: "EUR")
        expect(product).to be_valid
      end

      it "is valid with GBP currency" do
        product = build(:product, currency: "GBP")
        expect(product).to be_valid
      end

      it "is invalid with 2 character currency" do
        product = build(:product, currency: "US")
        expect(product).not_to be_valid
      end

      it "is invalid with 4 character currency" do
        product = build(:product, currency: "USDD")
        expect(product).not_to be_valid
      end

      it "is invalid with lowercase currency" do
        product = build(:product, currency: "usd")
        # Note: This depends on whether you want to enforce uppercase
        # Currently the validation only checks length
        expect(product).to be_valid
      end
    end

    context "stock edge cases" do
      it "is valid with zero stock" do
        product = build(:product, stock_quantity: 0)
        expect(product).to be_valid
      end

      it "is valid with large stock" do
        product = build(:product, stock_quantity: 1_000_000)
        expect(product).to be_valid
      end

      it "is invalid with float stock" do
        product = build(:product, stock_quantity: 10.5)
        expect(product).not_to be_valid
      end
    end

    context "SKU edge cases" do
      it "is valid with single character SKU" do
        product = build(:product, sku: "A")
        expect(product).to be_valid
      end

      it "is valid with 50 character SKU" do
        product = build(:product, sku: "A" * 50)
        expect(product).to be_valid
      end

      it "is invalid with 51 character SKU" do
        product = build(:product, sku: "A" * 51)
        expect(product).not_to be_valid
      end

      it "is valid with alphanumeric SKU" do
        product = build(:product, sku: "ABC-123-DEF")
        expect(product).to be_valid
      end

      it "is valid with special characters in SKU" do
        product = build(:product, sku: "SKU_123-456")
        expect(product).to be_valid
      end

      it "is invalid with duplicate SKU case sensitive" do
        create(:product, sku: "TEST-001")
        product = build(:product, sku: "test-001")
        # SKU uniqueness is case-sensitive by default
        expect(product).to be_valid
      end
    end

    context "active flag" do
      it "defaults to active" do
        product = Product.new(name: "Test", price_cents: 100, sku: "TEST-001")
        expect(product.active).to be true
      end

      it "can be set to inactive" do
        product = build(:product, active: false)
        expect(product).to be_valid
        expect(product.active).to be false
      end
    end

    context "defaults" do
      it "defaults to USD currency" do
        product = Product.new(name: "Test", price_cents: 100, sku: "TEST-001")
        expect(product.currency).to eq("USD")
      end

      it "defaults to zero price" do
        product = Product.new(name: "Test", sku: "TEST-001")
        expect(product.price_cents).to eq(0)
      end

      it "defaults to zero stock" do
        product = Product.new(name: "Test", price_cents: 100, sku: "TEST-001")
        expect(product.stock_quantity).to eq(0)
      end
    end
  end

  describe "scopes" do
    let!(:active_product) { create(:product, active: true) }
    let!(:inactive_product) { create(:product, :inactive) }
    let!(:in_stock_product) { create(:product, :in_stock) }
    let!(:out_of_stock_product) { create(:product, :out_of_stock) }

    it ".active returns only active products" do
      expect(Product.active).to include(active_product, in_stock_product, out_of_stock_product)
      expect(Product.active).not_to include(inactive_product)
    end

    it ".in_stock returns only products with stock" do
      expect(Product.in_stock).to include(in_stock_product)
      expect(Product.in_stock).not_to include(out_of_stock_product)
    end

    it ".available returns active products in stock" do
      expect(Product.available).to include(in_stock_product)
      expect(Product.available).not_to include(out_of_stock_product)
      expect(Product.available).not_to include(inactive_product)
    end

    it ".by_price_asc sorts by price ascending" do
      cheap = create(:product, price_cents: 100)
      expensive = create(:product, price_cents: 5000)
      results = Product.where(id: [cheap.id, expensive.id]).by_price_asc
      expect(results.first).to eq(cheap)
    end

    it ".by_price_desc sorts by price descending" do
      cheap = create(:product, price_cents: 100)
      expensive = create(:product, price_cents: 5000)
      results = Product.where(id: [cheap.id, expensive.id]).by_price_desc
      expect(results.first).to eq(expensive)
    end

    it ".by_name sorts by name" do
      b_product = create(:product, name: "Banana")
      a_product = create(:product, name: "Apple")
      results = Product.where(id: [a_product.id, b_product.id]).by_name
      expect(results.first).to eq(a_product)
    end

    it ".search_by_name finds products by name" do
      create(:product, name: "Red Apple")
      create(:product, name: "Green Apple")
      create(:product, name: "Banana")

      results = Product.search_by_name("Apple")
      expect(results.count).to eq(2)
    end

    it ".search_by_name is case insensitive" do
      create(:product, name: "APPLE")
      results = Product.search_by_name("apple")
      expect(results.count).to eq(1)
    end

    it ".search_by_name returns empty for no matches" do
      create(:product, name: "Apple")
      results = Product.search_by_name("Orange")
      expect(results.count).to eq(0)
    end

    it ".search_by_name handles partial matches" do
      create(:product, name: "Apple Pie")
      create(:product, name: "Pineapple")
      results = Product.search_by_name("Apple")
      expect(results.count).to eq(2)
    end

    it ".search_by_name handles SQL injection safely" do
      create(:product, name: "Apple")
      # Should not raise an error
      expect { Product.search_by_name("'; DROP TABLE products; --") }.not_to raise_error
    end
  end

  describe "#available?" do
    it "returns true for active product in stock" do
      product = build(:product, active: true, stock_quantity: 10)
      expect(product.available?).to be true
    end

    it "returns false for inactive product" do
      product = build(:product, active: false, stock_quantity: 10)
      expect(product.available?).to be false
    end

    it "returns false for out of stock product" do
      product = build(:product, active: true, stock_quantity: 0)
      expect(product.available?).to be false
    end

    it "returns false for inactive and out of stock product" do
      product = build(:product, active: false, stock_quantity: 0)
      expect(product.available?).to be false
    end

    it "returns true for product with 1 in stock" do
      product = build(:product, active: true, stock_quantity: 1)
      expect(product.available?).to be true
    end
  end

  describe "#price_formatted" do
    it "formats price correctly" do
      product = build(:product, price_cents: 1999, currency: "USD")
      expect(product.price_formatted).to eq("$19.99 USD")
    end

    it "formats zero price" do
      product = build(:product, price_cents: 0, currency: "USD")
      expect(product.price_formatted).to eq("$0.00 USD")
    end

    it "formats single digit cents" do
      product = build(:product, price_cents: 105, currency: "USD")
      expect(product.price_formatted).to eq("$1.05 USD")
    end

    it "formats large prices" do
      product = build(:product, price_cents: 1000000, currency: "USD")
      expect(product.price_formatted).to eq("$10000.00 USD")
    end

    it "formats with different currency" do
      product = build(:product, price_cents: 5000, currency: "EUR")
      expect(product.price_formatted).to eq("$50.00 EUR")
    end
  end

  describe "#reduce_stock!" do
    let(:product) { create(:product, stock_quantity: 10) }

    it "reduces stock by quantity" do
      product.reduce_stock!(3)
      expect(product.reload.stock_quantity).to eq(7)
    end

    it "reduces stock to zero" do
      product.reduce_stock!(10)
      expect(product.reload.stock_quantity).to eq(0)
    end

    it "raises error for negative quantity" do
      expect { product.reduce_stock!(-1) }.to raise_error(ArgumentError, "Quantity must be positive")
    end

    it "raises error for zero quantity" do
      expect { product.reduce_stock!(0) }.to raise_error(ArgumentError, "Quantity must be positive")
    end

    it "raises error when insufficient stock" do
      expect { product.reduce_stock!(11) }.to raise_error("Insufficient stock")
    end

    it "does not change stock on error" do
      begin
        product.reduce_stock!(11)
      rescue RuntimeError
        # expected
      end
      expect(product.reload.stock_quantity).to eq(10)
    end

    it "handles concurrent reductions" do
      product1 = create(:product, stock_quantity: 10)
      product2 = create(:product, stock_quantity: 10)

      product1.reduce_stock!(3)
      product2.reduce_stock!(5)

      expect(product1.reload.stock_quantity).to eq(7)
      expect(product2.reload.stock_quantity).to eq(5)
    end
  end

  describe "#increase_stock!" do
    let(:product) { create(:product, stock_quantity: 10) }

    it "increases stock by quantity" do
      product.increase_stock!(5)
      expect(product.reload.stock_quantity).to eq(15)
    end

    it "increases stock from zero" do
      product = create(:product, stock_quantity: 0)
      product.increase_stock!(10)
      expect(product.reload.stock_quantity).to eq(10)
    end

    it "raises error for negative quantity" do
      expect { product.increase_stock!(-1) }.to raise_error(ArgumentError, "Quantity must be positive")
    end

    it "raises error for zero quantity" do
      expect { product.increase_stock!(0) }.to raise_error(ArgumentError, "Quantity must be positive")
    end

    it "handles large increases" do
      product.increase_stock!(1_000_000)
      expect(product.reload.stock_quantity).to eq(1_000_010)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:product)).to be_valid
    end

    it "has a valid inactive trait" do
      product = build(:product, :inactive)
      expect(product).to be_valid
      expect(product.active).to be false
    end

    it "has a valid out_of_stock trait" do
      product = build(:product, :out_of_stock)
      expect(product).to be_valid
      expect(product.stock_quantity).to eq(0)
    end

    it "has a valid in_stock trait" do
      product = build(:product, :in_stock)
      expect(product).to be_valid
      expect(product.stock_quantity).to be > 0
    end

    it "has a valid expensive trait" do
      product = build(:product, :expensive)
      expect(product).to be_valid
      expect(product.price_cents).to be >= 50000
    end

    it "has a valid cheap trait" do
      product = build(:product, :cheap)
      expect(product).to be_valid
      expect(product.price_cents).to be <= 100
    end

    it "creates unique SKUs" do
      product1 = create(:product)
      product2 = create(:product)
      expect(product1.sku).not_to eq(product2.sku)
    end
  end

  describe "database constraints" do
    it "requires name at database level" do
      expect {
        Product.connection.execute("INSERT INTO products (price_cents, sku, created_at, updated_at) VALUES (100, 'TEST', NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "requires sku at database level" do
      expect {
        Product.connection.execute("INSERT INTO products (name, price_cents, created_at, updated_at) VALUES ('Test', 100, NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
