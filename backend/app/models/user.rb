class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :borrowings, dependent: :destroy

  enum :role, { member: 0, librarian: 1 }

  validates :first_name, presence: true
  validates :last_name, presence: true
end
