Trunk::Application.routes.draw do

  root :to => "front_page#home", :as => 'home', :via => :get

  match '/login' => "session#new", :via => :get
  match '/login' => "session#create", :via => :post
  match '/logout' => "session#destroy", :via => :delete
  match '/toggle_status' => "session#update", :via => :put
  match '/child' => "session#show", :via => :get, :as => 'session'
  match '/bypass/:id' => "session#bypass", :via => :get

  resource :account, :only => [:edit, :update] do
    post 'reset_password', :on => :member
  end
  match '/alternate_login' => "accounts#forgot_password", 
                       :as => 'alternate_login', :via => :get

  match 'schools/search' => "schools#search", :as => 'schoolfinder',
                                              :via => :get
  match 'signup' => "schools#new", :via => :get
  match 'signup' => "schools#create", :via => :post

  scope "/admin" do

    match '' => "front_page#admin", :via => :get, :as => 'admin_home'
    resource :school, :only => [:show, :edit, :update]
    scope :module => "term" do
      resources :terms, :except => :index do
        resources :tracks, :except => [:show, :index] 
        resources :marking_periods, :except => [:show, :index, :edit, :update]
        resources :marks, :except => [:new, :show], 
                          :controller => :reported_grades, 
                          :as => :reported_grades
        resource :staging, :controller => :staging do
          get :search, :on => :collection
        end
        get :start, :on => :collection
      end
    end

    scope :module => "catalog" do
      resource :catalog, :only => [:new, :create, :edit, :update]
      resources :departments, :except => :show do
        resources :subjects
      end
    end
  end
 
  scope :via => :get do
    match '/sections/:section_id/subject' => "subjects#show",
                                          :as => :section_subject
    match '/sections/:section_id/department' => "subjects#index",
                                          :as => :section_department
  end

  match 'search' => "search#index", :via => :get

  constraints :id => /students|teachers|admin\/administrators/ do
    controller 'people/enter' do
      [:names, :details, :multiple].each do |action|
        match ":id/enter/#{action}" => action, :as => "enter_#{action}",
                                                :via => [:get, :post]
      end
    end
    scope :path => ':id', :module => :upload, :as => :users do
      resource :upload, :controller => :users, :only => [:new, :create]
    end
  end

  scope :path => 'teachers' do
    scope :path => 'teaching_load', :as => :teaching_load do
      resource :upload, :controller => 'upload/teacher_schedules', 
                        :only => [:new, :create]
    end
    scope :path => ':teacher_id' do
      scope :as => :teacher do
        resources :sections, :only => [:show, :edit, :update] do
          scope :module => :gradebook do
            resources :assignments, :only => [:show, :index] do
              get :performance, :on => :collection
            end
            resources :marks, :only => [:show, :index]
            resource :attendance, :controller => :attendance, 
                                  :only => :show
          end
        end
      end
      resource :teaching_load, :except => :show, 
                               :controller => :teaching_load do
        member do
          post :set_departments
        end
      end
    end
  end

  scope :path => '/students' do
    resources :attendance, :controller => :attendance
  end

  scope :module => "people" do
    
    scope :path => '/students' do
      resources :parents, :only => :index
    end

    resources :students do
      member do
        get 'attendance', 'sections', 'marks'
      end
      resources :parents
    end

    scope :path => '/admin' do
      resources :administrators do
        get 'search', :on => :collection
        post 'search', :on => :collection
      end
    end

    resources :teachers do
      get :logins, :on => :member
    end

  end

  scope :path => 'sections', :as => 'personal' do
    resource :teaching_load, :except => :show, :controller => :teaching_load
  end
  resources :sections, :except => [:new, :create] do
    scope :module => "gradebook" do
      resources :assignments do
        get :performance, :on => :collection
      end
      resource :gradebook, :controller => :gradebook, 
                           :only => [:show, :update] do
        collection do
          get :sort
          post :sort
          put :sort
        end
      end
      resources :marks
      resource :enrollment, :controller => :enrollment, 
                           :only => [:new, :create, :destroy] do
        get :search, :on => :collection
        post :search, :on => :collection
      end
      resource :seating_chart, :controller => :seating_chart

      resource :attendance, :controller => :attendance, 
                            :only => [:edit, :show, :update]
    end
  end
  scope :module => :upload, :path => 'sections/:section_id' do
    scope :path => '/gradebook', :as => :grades do
      resource :upload, :controller => :grades, :only => [:new, :create]
    end
    scope :path => '/enrollment', :as => :enrollment do
      resource :upload, :controller => :enrollment, :only => [:new, :create]
    end
  end
  scope :module => "gradebook", :via => :get,
        :path => "students/:id/classes/:section_id" do
    match '' => "individual#show", :as => 'rbe'
    match 'assignments' => "individual#assignments", :as => 'rbe_assignments'
    match 'marks' => "individual#marks", :as => 'rbe_marks'
    match 'attendance' => "individual#attendance", :as => 'rbe_attendance'
  end

  scope :module => "beast", :path => "discussions/:scope" do
    resources :forums do

      resources :topics, :except => :index do
        resources :posts, :except => :show
        resource :monitorship, :only => [:create, :destroy]
      end
      resources :moderators, :except => [:new, :edit, :show] do
        get :search, :on => :collection
      end
      resources :posts, :except => [:show, :edit, :update, :new, :create]
    end
    resources :members, :only => [:index, :show], :as => :readers,
                        :controller => 'users' do
      resources :posts, :except => [:new, :create, :show, :edit, :update]
      match '/monitored' => "posts#monitored", :as => 'monitored_posts',
                                               :via => :get
    end
    resources :posts, :except => [:show, :edit, :update, :new, :create] do
      get :search, :on => :collection
    end
  end

  scope '/discussions', :via => :get do
    match '' => "beast/forums#index", :as => 'personal'
  end

  scope '/calendar' do
    controller "events", :via => :get do
      scope '/:year/:month' do
        constraints :year => /20\d{2}/, :month => /[01]?\d/ do
          defaults :month => Date.today.mon, :year => Date.today.year do
            match '', :action => "index", :as => "calendar"
            match 'student/:student_id', :action => "index",
                                         :as => "student_calendar"
            match "/:day", :action => "index", :as => "day"
          end
        end
      end
      match 'assignments/:assignment_id', :action => "assignment",
                                          :as => "assignment_as_event"
    end
    resources :events
  end

  scope '/classes' do
    controller "student", :via => :get do
      match '', :action => "index", :as => "student_classes"
      match ':section_id', :action => "show", :as => "student_class"
      match ':section_id/assignments', :action => "assignments",
                                       :as => "student_assignments"
      match ':section_id/assignments/:assignment_id',
                                       :action => "assignment",
                                       :as => "student_assignment"
      match ":section_id/marks", :action => "marks", :as => "student_marks"
    end
  end

  scope '/help', :via => :get do 
    match '/faq(/:action_name)' => "help/faq#display", :as => "faq"
    match '/page/:controller_name/:action_name' => "help/page#display",
                                                       :as => "help"
    match '/video/:id' => "help/general#video", :as => "video_help"
    match '(/:controller_name(/:action_name))'=> "help/general#display",
                                                    :as => "general_help"
  end
    match 'datebocks/help', :via => :get
    match 'dummy_for_test' => "dummy#dummy"
    match 'dummy_for_test_2' => "dummy#dummy_upload"
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)


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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end

