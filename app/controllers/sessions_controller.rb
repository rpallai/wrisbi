class SessionsController < ApplicationController
  skip_before_filter :authenticate, :except => [:destroy]

  def new
    logger.debug "session[:authenticate_redirected_from]: #{session[:authenticate_redirected_from]}"
  end

  def create
    @email = params[:email]
    session[:user_id] = User.find_by_email(@email).try(:authenticate, params[:password])
    if session[:user_id]
      logger.debug "session[:authenticate_redirected_from]: #{session[:authenticate_redirected_from]}"
      redirect_to(session[:authenticate_redirected_from] || root_path)
    else
      session[:notify] = "Invalid login"
      render :action => "new"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to :action => "new"
  end
end
