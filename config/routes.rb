Rails.application.routes.draw do
  devise_for :users
  devise_scope :user do
    authenticated :user do
      root 'dashboards#index', as: :root
    end
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
  resources :dashboards, only: [:index] do
    collection do
      get 'statistics'
      get 'trend_report'
      get 'lease_data'
    end
  end
  resources :leads do
    member do
      get :histories
      get "visits/new", action: :new_visit, as: :new_visit
      post "visits/create", action: :create_visit, as: :create_visit
      get "visits/:visit_id/edit", action: :edit_visit, as: :edit_visit
      delete "visits/:visit_id", action: :delete_visit, as: :delete_visit
      post :make_call
      get :localities
      get :fetch_source_subsource
      put :deactivate
      put :activate
      get "visits/:visit_id/print", action: :print_visit, as: :print_visit
    end
    collection do
      get ":status_id/stages", action: :stages
      get :import
      get 'calender_view', as: :calender_view, action: :calender_view
      post :import, action: :perform_import
      put :bulk_action
      get :export
      get :prepare_bulk_update
      get :call_logs
      get :download_call_log_recording
      get :outbound_logs
      get :dead_or_recycle
      put :import_bulk_update
      get :lead_counts
    end
  end
  resources :onsite_leads do
    collection do
      get :partner_leads
      get :get_leads
      get :fetch_users
    end
    member do
      post :edit_lead
      get :partner_lead_edit
      get :visit_details
      get "visits/:visit_id/edit", action: :edit_visit, as: :edit_visit
    end
  end
  namespace :leads do
    resources :notifications, only: [] do
      collection do
        get ':lead_id/send_sms', action: :send_sms, as: :send_sms
        get ':lead_id/template_detail/:template_id', action: :template_detail, as: 'template_detail'
        post ':template_id/:lead_id/update_template_detail', action: :update_template_detail, as: 'update_template_detail'
        post ':lead_id/shoot_notification/:notification_id', action: :shoot_notification, as: 'shoot_notification'

        get ':lead_id/send_email', action: :send_email, as: :send_email
        post ':lead_id/shoot_email', action: :shoot_email, as: :shoot_email
      end
    end
  end
  resources :payment_plans
  resources :cost_sheets do
    member do
      get :get_plan_details
    end
  end
  resources :notification_templates ,param: :uuid
  resources :file_exports do
    get :download
  end
  resources :campaigns ,param: :uuid do
    collection do
      get :download_sample_csv
      post :import_spend
    end
  end
  resources :call_ins, param: :uuid
  resources :stages, param: :uuid
  resources :projects, param: :uuid
  resources :communication_templates
  resources :exotel_sids, param: :uuid do
    collection do
      get :statistics
    end
  end
  resources :mcube_sids, param: :uuid
  resources :cloud_telephony_sids
  resources :brokers, param: :uuid do
    collection do
      get :bulk_update
      put :import_bulk_update
      get :import
      post :import, action: :perform_import
    end
  end
  resources :statuses
  resources :countries
  resources :cities
  resources :regions
  resources :localities
  resources :sources
  resources :sub_sources, param: :uuid
  resources :roles, except: [:new, :edit]
  namespace :users do
    resources :search_histories, only: [:index, :destroy]
  end
  resources :users, param: :uuid do
    collection do
      get :edit_profile
      patch :update_profile
      get :edit_user_config
      put :round_robin, action: :enable_round_robin
      delete :round_robin, action: :disable_round_robin
    end
  end
  namespace :companies do
    resources :inventories, param: :uuid
    resources :flats do
      collection do
        get :fetch_biz_flats
        get :fetch_projects
        get :booking
        get :search_lead
        get :search_broker
      end
      member do
        get :fetch_buildings
        get :flat_block_modal
        post :block_flat
        get :fetch_building_flats
        get :booking_form, as: :booking_form
        post :create_client
      end
    end
    resources :api_keys, param: :uuid
    resources :fb_pages, param: :fb_id do
      member do
        get :fb_forms
        get :new_fb_form
      end
    end
    resources :fb_forms, param: :form_no
  end
  resources :companies do
    member do
      get :fb_pages
      get "fb_pages/import", action: :prepare_import_fb_pages
      post "fb_pages/import", action: :import_fb_pages
      get :mobile_logo_form
      get :broker_form
      get :project_form
      get :shuffle_statues_form
      put :update_status_order
      get :sv_form
      get :renewals
      post :update_sv_form
    end
  end
  get :configurations, controller: 'leads', action: 'configurations', path: '/configurations'
  namespace :reports do
    get :source
    get :projects
    get :campaigns
    get :campaigns_report
    get "campaign/:campaign_uuid", action: :campaign_detail, as: :campaign_detail
    get :backlog
    get "closing_executive/backlog", action: :closing_executive_backlog
    get :dead
    get :leads
    get :source_wise_visits
    get :source_wise_inactive
    get :visits
    get :source_report
    get :presale_visits
    get :site_visit_userwise
    get :closing_executives
    get :trends
    get :activity
    get :site_visit_planned_tracker
    get :site_visit_planned
    get :customized_status_dashboard
    get :user_call_reponse_report
    get :scheduled_site_visits
    get :call_report
    get :sub_source
    get :channel_partner
    get :gre_source_report
    get :sales_dashboard
    get ':lead_id/scheduled_site_visits_detail', action: :scheduled_site_visits_detail, as: :scheduled_site_visits_detail
    get ":user_id/activity", action: :activity_details, as: :activity_details
  end

  namespace :api do
    post :login
    get :company_logo
    delete :logout
    get 'manifest', controller: 'manifest', action: 'show'
    namespace :mobile_crm do
      get :projects
      get :additional_settings
      get :settings
      get :status_wise_stage
      get :dashboard
      get :user_incentive_detail
      get :call_logs
      get 'suggest/users', action: :suggest_users
      get 'suggest/projects', action: :suggest_projects
      get 'suggest/managers', action: :suggest_managers
      resources :leads, only: [:index, :show, :update, :create], param: :uuid do
        collection do
          get :magic_fields
          post :make_call
          get :settings
        end
        member do
          delete "visits/:visit_id", action: :delete_visit
          post :log_call_attempt
          get :histories
          put :deactivate
        end
      end
      resources :saved_searches, only: [:index, :create, :destroy]
      get "companies/configs", to: "site_visit_configurations#settings"
      get "companies/:uuid/get_users", to: "site_visit_informations#get_users"
      get "companies/:uuid/get_brokers", to: "site_visit_informations#get_brokers"
      get "companies/:uuid/get_brokers_firm_name", to: "site_visit_informations#get_brokers_firm_name"
      get "companies/:uuid/get_brokers_by_firm_name", to: "site_visit_informations#get_brokers_by_firm_name"
      get "companies/:uuid/get_sub_sources", to: "site_visit_informations#get_sub_sources"
      get "companies/:uuid/get_sources", to: "site_visit_informations#get_sources"
      get "companies/:uuid/get_cities", to: "site_visit_informations#get_cities"
      get "companies/:uuid/get_visit_status", to: "site_visit_informations#get_visit_status"
      get "companies/:uuid/get_locality", to: "site_visit_informations#get_locality"
      get "companies/:uuid/get_projects", to: "site_visit_informations#get_projects"
      post "companies/:uuid/leads", to: "site_visit_informations#create_lead"
      get "companies/:uuid/settings", to: "site_visit_informations#settings"
      get "companies/:uuid/broker", to: "site_visit_informations#fetch_broker"
      post "companies/:uuid/brokers", to: "site_visit_informations#create_broker"
      get "companies/:uuid/fetch_leads", to: "site_visit_informations#fetch_lead"
      get "companies/:uuid/get_executives", to: "site_visit_informations#get_executives"
      get "companies/:uuid/partners/settings", to: "site_visit_informations#partner_settings"
      get "companies/:uuid/get_cps", to: "site_visit_informations#get_cp_ids"
      scope 'companies/:uuid' do
        namespace :sv_apps do
          resources :otps, only: :create do
            collection do
              get :validate
            end
          end
        end
      end
    end
    namespace :third_party_service do
      resources :exotels, only: [] do
        collection do
          post :callback
          get :incoming_call_back
          get :incoming_connection
          get :incoming_call
          get :marketing_incoming_call
          get :notify_users
          get :marking_call_callback
        end
      end
      resources :mcubes, only: [] do
        collection do
          post :callback
          post :incoming_call
          post :ctc_ic
          post :hangup
          post ':uuid/auto_dailer_hangup', to: "mcubes#auto_dailer_hangup"
        end
      end
      resources :caller_desk, only: [] do
        collection do
          get :hangup
          get :call_logs
        end
      end
      resources :my_operator, only: [], param: :uuid do
        member do
          post :hangup
        end
      end
      resources :knowlarities, only: [] do
        collection do
          post :callback
          post ':uuid/incoming_call', to: "knowlarities#incoming_call"
        end
      end
      resources :teleteemtech, only: [] do
        collection do
          get ':uuid/incoming_call', to: "teleteemtech#incoming_call"
        end
      end
      resources :czentrixcloud, only: [] do
        collection do
          post :callback
          post :incoming_call_connect
          post :incoming_call_disconnect
          get ':call_id/dialwhom', action: :dialwhom
        end
      end
      resources :ivr_manager, only: [] do
        collection do
          post :incoming_call
          post :hangup
        end
      end
      resources :way_voice, only: [] do
        collection do
          post ':uuid/outbound_disconnect', controller: "way_voice", action: "outbound_disconnect"
          post ':uuid/incoming_call', controller: "way_voice", action: "incoming_call"

        end
      end
      resources :tata_teleservice, only: [] do
        collection do
          post ':uuid/incoming_call', controller: "tata_teleservice", action: "incoming_call"
          post :callback
          post ':uuid/auto_dailer_hangup', controller: "tata_teleservice", action: "auto_dailer_hangup"
        end
      end
      resources :slash_rtcservice, only: [] do
        collection do
          post :callback
          post ':uuid/incoming_call', controller: "slash_rtcservice", action: "incoming_call"
          post :hangup
        end
      end

      resources :twispire, only: [] do
        collection do
          post ':uuid/incoming_call', controller: "twispire", action: "incoming_call"
        end
      end

      resources :call_logs, only: [] do
        collection do
          post ':uuid/incoming_call', controller: "call_logs", action: "incoming_call_hangup"
        end
      end
    end
  end

  namespace :internal, defaults: {format: 'json'} do
    post "companies/:uuid/brokers", to: "brokers#create_broker"
    post "companies/:uuid/leads", to: "brokers#create_lead"
    post "companies/:uuid/leads/inactive",to: "brokers#set_lead_inactive"
  end

  namespace :public do
    post "companies/:uuid/leads", controller: "company_leads", action: "create_lead"
    post "companies/:uuid/jd_leads", controller: "company_leads", action: "create_jd_lead"
    post "companies/:uuid/leads-all", controller: "company_leads", action: "create_leads_all"
    post "companies/:uuid/wix_lead", controller: "company_leads", action: "create_wix_leads"
    post "companies/:uuid/whatspp_lead_create", controller: "company_leads", action: "whatspp_lead_create"
    post "companies/:uuid/create_smartping_leads", controller: "company_leads", action: "create_smartping_leads"
    patch "companies/:uuid/whatspp_lead_update", controller: "company_leads", action: "whatspp_lead_update"
    post "companies/:uuid/create_external_lead", controller: "company_leads", action: "create_external_lead"
    get "companies/:uuid/settings", controller: "company_leads", action: "settings"
    post "companies/:uuid/google_ads", controller: "company_leads", action: "google_ads"
    match "companies/:uuid/magicbricks", controller: "company_leads", action: "magicbricks", via: [:get, :post]
    post "companies/:uuid/nine_nine_acres", controller: "company_leads", action: "nine_nine_acres"
    post "companies/:uuid/telecalling/leads", controller: "telecalling", action: "create_lead"
    post "companies/:uuid/housing", controller: "company_leads", action: "housing"
    patch "companies/:uuid/lead_update", controller: "company_leads", action: "lead_update"
    patch "companies/:uuid/update_lead_interests", controller: "company_leads", action: "lead_update_on_project"
    namespace :leads do
      post "call-in/create", action: :call_in_create
      get "call_in/sarva/create", action: :sarva_create
      post "partner/create", action: :partner_create
    end
    namespace :companies do
      get ':uuid/external_api/projects', controller: "external_api", action: "projects"
    end
    namespace :facebook do
      get :leads, action: :callback
      post :leads, action: :create_lead
      post :create_fb_leads, action: :create_fb_leads
    end
  end

  mount Resque::Server.new, :at => "/resque"
end
