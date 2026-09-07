class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :auth_tokens, dependent: :destroy

  # Valid roles
  ROLES = %w[customer admin].freeze

  # Validations
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validates :role, presence: true, inclusion: { in: ROLES }

  # Normalize email before validation
  before_validation :normalize_email

  # Scopes
  scope :customers, -> { where(role: "customer") }
  scope :admins, -> { where(role: "admin") }

  # Role predicates
  def customer?
    role == "customer"
  end

  def admin?
    role == "admin"
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
