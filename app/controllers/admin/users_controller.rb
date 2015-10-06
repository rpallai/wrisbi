class Admin::UsersController < ApplicationController
  before_filter :needs_root

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to :action => "index"
    else
      render :action => "new"
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      redirect_to :action => "index"
    else
      render :action => "edit"
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to :action => "index"
  end
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :root)
  end
end
