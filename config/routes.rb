Rails.application.routes.draw do
    # Main plugin routes
    get 'email_receiver', to: 'email_receiver#index'
    post 'email_receiver/update_settings', to: 'email_receiver#update_settings'
    post 'email_receiver/test_connection', to: 'email_receiver#test_connection'
    match 'email_receiver/receive_email', to: 'email_receiver#receive_email', via: [:post]
    get 'email_receiver/fetch_emails', to: 'email_receiver#fetch_emails'
  end