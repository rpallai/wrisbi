class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate

  private
  def authenticate
    if session[:user_id]
      @current_user = @user = User.find(session[:user_id])
    elsif via_api?
      authenticate_or_request_with_http_basic do |email, password|
        @current_user = @user = session[:user_id] = User.find_by_email(email).try(:authenticate, password)
      end
    else
      session[:authenticate_redirected_from] = url_for(:only_path => true)
      redirect_to(new_session_url)
    end
  end

  def via_api?
    request.format == Mime::XML or request.format == Mime::JSON
  end
  helper_method :via_api?

  def needs_root
    render_access_denied unless @current_user.root?
  end
  def needs_treasury_supervisor(treasury = @treasury)
    render_access_denied unless treasury.supervisors.include?(@current_user)
  end
  def needs_deeply_concerned(treasury = @treasury)
    unless treasury.supervisors.include?(@current_user) or
        (treasury.person_of_user(@current_user) and treasury.person_of_user(@current_user).bookkeeper?)
      render_access_denied
    end
  end
  def needs_concerned(treasury = @treasury)
    render_access_denied unless @current_user.concerned_treasuries.include? treasury
  end

  def render_access_denied
    render :text => "Access denied", :status => 401
  end

  def mobile_device?
    if session[:mobile_override]
      session[:mobile_override] == "1"
    else
      # Season this regexp to taste. I prefer to treat iPad as non-mobile.
      (request.user_agent =~ /Mobile|webOS/) && (request.user_agent !~ /iPad/)
    end
  end
  helper_method :mobile_device?
end
