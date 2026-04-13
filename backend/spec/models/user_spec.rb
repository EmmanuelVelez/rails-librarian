require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
  end

  describe "enum" do
    it { should define_enum_for(:role).with_values(member: 0, librarian: 1) }
  end

  describe "defaults" do
    it "defaults role to member" do
      user = build(:user)
      expect(user.role).to eq("member")
    end
  end
end
