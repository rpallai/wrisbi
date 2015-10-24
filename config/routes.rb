Wrisbi::Application.routes.draw do
  resource :user, :only => [:index, :edit, :update]
  resource :session, :only => [:new, :create, :destroy]

  resources :categories, :except => [:index, :new, :show], :requirements => { :class_name => "Category" }
  resources :payees, :except => [:index, :new]
  resources :businesses, :except => [:index, :new]
  resources :transactions, :only => :destroy do
    member do
      post 'do_ack'
    end
  end
  resources :accounts, only: [:show]

  resources :treasuries, :only => [], :requirements => { :class_name => "Treasury" } do
    resources :categories, :only => [:index, :new], :requirements => { :class_name => "Category" }
    resources :payees, :only => [:index, :new]
    resources :businesses, :only => [:index, :new]
    resources :exporters, :only => [:index], :requirements => { :class_name => "Exporter" }
    namespace :exporter do
      resources :mailers, :only => [:index, :new], :requirements => { :class_name => "Exporter::Mailer" }
    end
  end

  namespace :exporter do
    resources :mailers, :except => [:index, :new], :requirements => { :class_name => "Exporter::Mailer" }
  end

  namespace :admin do
    resources :users, :except => [:show]
  end

  # just remember to delete public/index.html.
  #root :to => 'dashboard#index'
  root :to => 'treasuries#index'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  Dir.glob File.expand_path("plugins/*", Rails.root) do |plugin_dir|
    file = File.join(plugin_dir, "config/routes.rb")
    if File.exists?(file)
      begin
        instance_eval File.read(file)
      rescue Exception => e
        puts "An error occurred while loading the routes definition of #{File.basename(plugin_dir)} plugin (#{file}): #{e.message}."
        exit 1
      end
    end
  end
end
