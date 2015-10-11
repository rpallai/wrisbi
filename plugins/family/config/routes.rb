namespace :family do
  resources :categories, :only => [], :requirements => { :class_name => "Category" } do
    resources :titles, :only => :index, controller: 'view', action: 'titles'
    member do
      get :last_transaction_as_template, controller: 'transactions', action: 'template_by_category'
    end
  end
  resources :people, :except => [:show, :index, :new], :requirements => { :class_name => "Family::Person" } do
    resources :operations, :only => :index, controller: 'view', action: 'operations'
    resources :categories, :only => [] do
      resources :operations, :only => :index, controller: 'view', action: 'operations'
    end
    resources :accounts, :only => [:new], :requirements => { :class_name => "Family::Account" }
  end
  resources :accounts, :except => [:show, :index, :new], :requirements => { :class_name => "Family::Account" } do
    #resources :titles, :only => :index, controller: 'view', action: 'titles'
    resources :transactions, :only => :index, controller: 'view', action: 'transactions'
    resources :operations, :only => :index, controller: 'view', action: 'operations'
    resources :categories, :only => [] do
      resources :operations, :only => :index, controller: 'view', action: 'operations'
      resources :transactions, :only => :index, controller: 'view', action: 'transactions'
    end
  end
  resources :treasuries, :except => [:index], :requirements => { :class_name => "Family::Treasury" } do
    resources :transactions, :only => :index, controller: 'view', action: 'transactions'
    resources :transactions, :only => :new
    # ez ide nem igazan kell
    resources :titles, :only => :index, controller: 'view', action: 'titles' do
      collection do
        get :no_category, filter: 'no_category'
      end
    end
    #get 'titles_by_month', to: 'view#titles_by_month'
    resources :operations, :only => :index, controller: 'view', action: 'operations'
    resources :people, :only => [:new], :requirements => { :class_name => "Family::Person" }
  end
  resources :transactions, :only => [:edit, :create, :update] do
    collection do
      post :build_new_party, action: 'new_build_new_party'
      post :build_new_title, action: 'new_build_new_title'
      post :copy_title, action: 'new_copy_title'
      post :refresh, action: 'new_refresh'
    end
    member do
      patch :build_new_party, action: 'edit_build_new_party'
      patch :build_new_title, action: 'edit_build_new_title'
      patch :copy_title, action: 'edit_copy_title'
      patch :refresh, action: 'edit_refresh'
      get :as_template
    end
  end
end
