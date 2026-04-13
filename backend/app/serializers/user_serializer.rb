class UserSerializer
  def initialize(user)
    @user = user
  end

  def serializable_hash
    {
      id: @user.id,
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name,
      role: @user.role,
      created_at: @user.created_at
    }
  end
end
