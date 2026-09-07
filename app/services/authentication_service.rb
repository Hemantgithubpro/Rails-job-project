class AuthenticationService
  class AuthenticationError < StandardError; end
  class InvalidCredentialsError < AuthenticationError; end
  class UserExistsError < AuthenticationError; end

  def self.register(email:, password:, role: "customer")
    new.register(email: email, password: password, role: role)
  end

  def self.login(email:, password:)
    new.login(email: email, password: password)
  end

  def self.authenticate_token(token)
    new.authenticate_token(token)
  end

  def register(email:, password:, role: "customer")
    user = User.new(email: email, password: password, role: role)

    if user.save
      token = create_token(user)
      { user: user, token: token }
    else
      raise UserExistsError, user.errors.full_messages.join(", ")
    end
  end

  def login(email:, password:)
    user = User.find_by(email: email&.downcase&.strip)

    if user&.authenticate(password)
      token = create_token(user)
      { user: user, token: token }
    else
      raise InvalidCredentialsError, "Invalid email or password"
    end
  end

  def authenticate_token(token)
    auth_token = AuthToken.active.find_by(token: token)
    auth_token&.user
  end

  private

  def create_token(user)
    AuthToken.create!(user: user).token
  end
end
