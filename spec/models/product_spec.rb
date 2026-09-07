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

    it "defaults to active" do
      product = Product.new(name: "Test", price_cents: 100, sku: "TEST-001")
      expect(product.active).to be true
    end

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
      cheap = create(:product, :cheap, price_cents: 100)
      expensive = create(:product, :expensive, price_cents: 5000)
      expect(Product.by_price_asc.first).to eq(cheap)
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
      expect(Product.by_name.first).to eq(a_product)
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
  end

  describe "#reduce_stock!" do
    let(:product) { create(:product, stock_quantity: 10) }

    it "reduces stock by quantity" do
      product.reduce_stock!(3)
      expect(product.reload.stock_quantity).to eq(7)
    end

    it "raises error for negative quantity" do
      expect { product.reduce_stock!(-1) }.to raise_error(ArgumentError)
    end

    it "raises error for zero quantity" do
      expect { product.reduce_stock!(0) }.to raise_error(ArgumentError)
    end

    it "raises error when insufficient stock" do
      expect { product.reduce_stock!(11) }.to raise_error("Insufficient stock")
    end
  end

  describe "#increase_stock!" do
    let(:product) { create(:product, stock_quantity: 10) }

    it "increases stock by quantity" do
      product.increase_stock!(5)
      expect(product.reload.stock_quantity).to eq(15)
    end

    it "raises error for negative quantity" do
      expect { product.increase_stock!(-1) }.to raise_error(ArgumentError)
    end

    it "raises error for zero quantity" do
      expect { product.increase_stock!(0) }.to raise_error(ArgumentError)
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
  end
end
