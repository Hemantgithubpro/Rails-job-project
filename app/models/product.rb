class Product < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :price_cents, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :stock_quantity, presence: true,
                             numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sku, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :available, -> { active.in_stock }
  scope :by_price_asc, -> { order(price_cents: :asc) }
  scope :by_price_desc, -> { order(price_cents: :desc) }
  scope :by_name, -> { order(name: :asc) }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  # Check if product is available for purchase
  def available?
    active? && stock_quantity > 0
  end

  # Format price for display
  def price_formatted
    "$#{'%.2f' % (price_cents / 100.0)} #{currency}"
  end

  # Reduce stock by quantity
  def reduce_stock!(quantity)
    raise ArgumentError, "Quantity must be positive" unless quantity.positive?
    raise "Insufficient stock" if quantity > stock_quantity

    update!(stock_quantity: stock_quantity - quantity)
  end

  # Increase stock by quantity
  def increase_stock!(quantity)
    raise ArgumentError, "Quantity must be positive" unless quantity.positive?

    update!(stock_quantity: stock_quantity + quantity)
  end
end
