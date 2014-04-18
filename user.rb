class User
  include BCrypt

  property :id, Serial, :key => true
  property :username, String, :length => 3..50
  property :password, BCryptHash
end
