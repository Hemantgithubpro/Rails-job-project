class AuthToken < ApplicationRecord
  belongs_to :user

  # Token expires after 7 days by default
  DEFAULT_EXPIRATION = 7.days

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def expired?
    expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(32)
  end

  def set_expiration
    self.expires_at ||= DEFAULT_EXPIRATION.from_now
  end
end
