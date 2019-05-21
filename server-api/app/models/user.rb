require('securerandom')
class User < ApplicationRecord
	attr_accessor :password
	validates :handle, presence: true, uniqueness: true, on: :create
	validates :password, presence: true, confirmation: true, length: {in: 8..32}, on: :create
	before_save :encrypt_password
	def self.login(params)
		puts("ONE")
		user = User.find_by(handle: params[:handle])
		if user.present?
			puts("TWO")
			password = BCrypt::Engine.hash_secret(params[:password], user.salt)
			if (user.crypted_password == password)
				puts("THREE")
				return user
			else
				puts("FOUR")
				return {errors: "Login failed!", status: 403}
			end
		end
	end
	protected
	def encrypt_password
		if self.password.present? && self.password_confirmation.present?
			self.salt				= BCrypt::Engine.generate_salt
			self.crypted_password	= BCrypt::Engine.hash_secret(self.password, salt)
		end
	end
end
