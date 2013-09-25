Ignition::Application.routes.draw do
  resources :groups do
  	# Route for notifying and re-invite
		member do
			put 'notify'
			put 'remove_member'
		end
	end

  devise_for :users 
#  devise_scope :user do
#  	# Send user to admin index after updating the profile, really should
#  	# add users controller for managing users.
# 		get 'users', to: 'admin#index', as: :user_root
#	end
  scope :admin do
  	resources :users
	end
	
  get "home/index"
  
  get "home/support"
  
  get "home/contact"

  get "home/about"

  get "admin/help"

  get "admin/index"
  
  get "admin/oops"

  get "admin/calendar"

  get "admin" => 'admin#index'  
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
 	# devise_for :users  
  
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'  
end
