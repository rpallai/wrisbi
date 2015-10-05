namespace :user do
  desc "Create a new user."
  task :create_root => :environment do
    printf "E-mail: "
    email = STDIN.readline.chomp
    printf "Password: "
    password = STDIN.readline.chomp

    user = User.create!(:email => email, :root => true,
      :password => password, :password_confirmation => password)

    puts "Root `#{email}' created, uid is: #{user.id}"
  end

  task :list => :environment do
    users = User.all

    if users.empty?
      puts "no users found"
    else
      users.each do |user|
        puts "##{user.id}: #{user.email} (#{user.root?})"
      end
    end
  end
end
