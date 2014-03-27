Ignition::Application.routes.draw do
  resources :projects

  resources :subscriptions

  resources :groups do
  	# Route for notifying and re-invite
		member do
			put 'notify'
			put 'remove_member'
		end
	end

  devise_for :users, path_prefix: 'auth'

	resources :users do
	  # Account is an embedded document for a user with limited actions
	  resources :accounts, only: [:new, :create, :edit, :update, :destroy]
	end

  get   "home/index"
  get   "home/support"
  get   "home/contact"
  post  "home/create_contact"
  get   "home/about"
  get   "admin/help"
  get   "admin/index"
  get   "admin/oops"
  get   "admin/calendar"

  get "admin" => 'admin#index'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'
end
