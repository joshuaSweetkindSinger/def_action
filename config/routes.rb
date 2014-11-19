SampleApp::Application.routes.draw do

  PagesController.routes.each do |action, route|
    # puts "match #{route.path}, via: #{route.verb}, to: #{route.to}, as: #{route.name}"
    puts route.to_s

    # match route.path, via: route.verb, to: route.to, as: route.name
  end

  # root to: 'pages#home'
  #match '/about', to: 'pages#about'
  #match '/contact', to: 'pages#contact'
  #match '/help', to: 'pages#help'
  #match '/sign_up', to: 'pages#sign_up'
  #match '/sign_in', to: 'pages#sign_in_page', as: :sign_in
  #match '/users_index', to: 'pages#users_index'

  #match '/create_user', to:'pages#create_user', via: :post, as: :create_user
  #match '/create_post', to: 'pages#create_post', via: :post
  #match '/sign_in_to_session', to: 'pages#sign_in_to_session', via: :post, as: :sign_in_to_session

  #match '/sign_out', to: 'pages#sign_out_of_session', via: :delete, as: :sign_out
  #match '/delete_post', to: 'pages#delete_post', via: :delete

  #match '/update_user', to:'pages#update_user', via: :post, as: :update_user
  #match '/delete_user/:user_id', to:'pages#delete_user', via: :delete, as: :delete_user
  #match '/user_profile/:user_id', to: 'pages#user_profile', as: :user_profile
  #match '/users_being_followed/:user_id', to: 'pages#users_being_followed', as: :users_being_followed
  #match '/followers/:user_id', to: 'pages#followers', as: :followers
  #match '/edit_user/:user_id', to:'pages#edit_user', as: :edit_user
  #match '/follow_user/:id', via: :delete, to: 'pages#unfollow_user', as: :unfollow_user
  #match '/follow_user/:id', via: :post,   to: 'pages#follow_user',   as: :follow_user



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

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with 'root'
  # just remember to delete public/old_index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with 'rake routes'

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
