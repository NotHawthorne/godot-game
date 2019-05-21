class UsersController < ApplicationController
	def index
		@users = User.all
	end
	def show
		@user = User.find(params[:handle])
	end
	def create
		puts(user_params)
		@user = User.new(user_params)
		if @user.save
			render json: @user
		else
			render json: User::login(user_params)
		end
	end
	protected
	def	user_params
		params.require(:user).permit(:handle, :password, :password_confirmation)
	end
end
