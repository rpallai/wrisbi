# encoding: utf-8
module UsersHelper
  def show_email(email)
    email.gsub(/@.*/, '')
  end

  def show_users(users)
    users.map{|user| show_email user.email}*','
  end

  def users(scope = User.all)
    scope.collect{|user| [user.email, user.id] }
  end
end
