Rails.application.routes.draw do
    # API endpoint for receiving emails
    post 'email_receiver/receive_email', to: 'email_receiver#receive_email'
    post 'email_receiver/test_connection', to: 'email_receiver#test_connection'
    
    
    # Admin interface
    get 'email_receiver_admin', to: 'email_receiver#index'
    post 'email_receiver_admin/test_connection', to: 'email_receiver#test_connection'
end