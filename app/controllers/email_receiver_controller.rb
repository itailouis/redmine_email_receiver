# redmine_email_receiver/app/controllers/email_receiver_controller.rb
#require '/usr/local/bundle/gems/oauth2-2.0.9/lib/oauth2.rb'

class EmailReceiverController < ApplicationController
  before_action :require_admin
  layout 'admin'


      CLIENT_ID = 'cec0b1c2-4268-45ad-8d54-1e5d1a0a2e3c'
      CLIENT_SECRET = '65eadfc7-071e-4f98-b129-94b5596df2bc'
      TENANT_ID = '2ab9ba88-e1a4-4c9a-8ebc-0fce705d2f56'
      USER_EMAIL = 'innovation@fbc.co.zw'

      # Get access token
      def get_access_token
        #

        #client.client_credentials.get_token(scope: 'https://graph.microsoft.com/.default')

      end

  
  def index
    # Fix: Initialize @settings to empty hash if nil
    @settings = Setting.plugin_redmine_email_receiver || {}
  end
  
  def update_settings
    # Fix: Initialize settings to empty hash if nil
    settings = Setting.plugin_redmine_email_receiver || {}
    settings = settings.merge(params[:settings] || {})
    
    Setting.plugin_redmine_email_receiver = settings
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: 'index'
  end
  
  def test_connection
    # Fix: Initialize settings to empty hash if nil
    #token = get_access_token
    #Rails.inform "Access Token: #{token.token}"
    settings = params[:settings] || Setting.plugin_redmine_email_receiver || {}
    
    host = settings['imap_host']
    port = (settings['imap_port'] || 143).to_i
    ssl = settings['imap_ssl'] == '1'
    username = settings['imap_username']
    password = settings['imap_password']
    folder = settings['imap_folder'] || 'INBOX'
    
    # Validate input
    if host.blank? || username.blank? || password.blank?
      respond_to do |format|
        format.json { render json: { status: 'error', message: l(:error_connection_params_missing) } }
      end
      return
    end
    
    begin
      require 'net/imap'
      require 'oauth2'
      require 'microsoft_graph'




  client = MicrosoftGraph.new(
                   client_id: @settings['client_id'],
                   client_secret: @settings['client_secret'],
                   tenant_id: @settings['tenant_id'],
                   scope: 'https://graph.microsoft.com/.default');

      # Use TLSv1.2 explicitly regardless of ssl parameter
      Rails.logger.info "Connecting with TLSv1.2 to #{host}:#{port}"
      # Connect with TLSv1.2
      imap = Net::IMAP.new(host, port: port, ssl: ssl)

      
      # Login
      Rails.logger.info "Connection established using TLSv1.2"

      # Login
      Rails.logger.info "Attempting login with username: #{username}"
      #imap.login(username, '')
      imap.authenticate('XOAUTH2', username, "eyJ0eXAiOiJKV1QiLCJub25jZSI6IjlPUzJGN2s5QmxyaHhBM3BXRVdGNVVwVHNobFJwZURMeEdqV0JKT2VaNlEiLCJhbGciOiJSUzI1NiIsIng1dCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSIsImtpZCI6IkNOdjBPSTNSd3FsSEZFVm5hb01Bc2hDSDJYRSJ9.eyJhdWQiOiJodHRwczovL291dGxvb2sub2ZmaWNlMzY1LmNvbSIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzJhYjliYTg4LWUxYTQtNGM5YS04ZWJjLTBmY2U3MDVkMmY1Ni8iLCJpYXQiOjE3NDcyOTMwMDksIm5iZiI6MTc0NzI5MzAwOSwiZXhwIjoxNzQ3Mjk2OTA5LCJhaW8iOiJBU1FBMi84WkFBQUFzeHphMXJOb1dJV0Njc2JQdmkwaHM5SHJFU1h6cXZSbElvUFA2cmkyY0hvPSIsImFwcF9kaXNwbGF5bmFtZSI6Iklubm92YXRpb24iLCJhcHBpZCI6ImNlYzBiMWMyLTQyNjgtNDVhZC04ZDU0LTFlNWQxYTBhMmUzYyIsImFwcGlkYWNyIjoiMSIsImlkcCI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzJhYjliYTg4LWUxYTQtNGM5YS04ZWJjLTBmY2U3MDVkMmY1Ni8iLCJpZHR5cCI6ImFwcCIsIm9pZCI6IjlkNjU1ZGY2LTIxYWEtNDU5OS1iNDA4LTUwMjY0ZTgxMmUwNCIsInJoIjoiMS5BWUlBaUxxNUtxVGhta3lPdkFfT2NGMHZWZ0lBQUFBQUFQRVB6Z0FBQUFBQUFBQ0NBQUNDQUEuIiwic2lkIjoiMDA0ZTlkMTktZTI4MS1hNTVlLTk1ZTItNzQwMzUwMDZiYWE1Iiwic3ViIjoiOWQ2NTVkZjYtMjFhYS00NTk5LWI0MDgtNTAyNjRlODEyZTA0IiwidGlkIjoiMmFiOWJhODgtZTFhNC00YzlhLThlYmMtMGZjZTcwNWQyZjU2IiwidXRpIjoiZEJsUXNudlZvRXE2d2NFYi0xVU9BQSIsInZlciI6IjEuMCIsIndpZHMiOlsiMDk5N2ExZDAtMGQxZC00YWNiLWI0MDgtZDVjYTczMTIxZTkwIl0sInhtc19hdWRfZ3VpZCI6IjAwMDAwMDAyLTAwMDAtMGZmMS1jZTAwLTAwMDAwMDAwMDAwMCIsInhtc19pZHJlbCI6IjcgMiIsInhtc19yZCI6IjAuNDJMallCSmlhbUlVRXVGZ0Z4STRmdjlWcWh6N0RQLU5tbE8yUnVaLTJnTVU1UlFTWU5KYnRMSFBLODZ4TTJtMnhvcDF1ZE1BIn0.DJNYYkUam0l-uSYMpUKzbjSWPLjbqkmRZih9Vr4o8kHh4WTTjmJTybCdfpkzpDAK2Pqb5Q2Un90tEp60SvQyr0yXY_XAEP7jz8The7vR_FjYazqVbgyGqH_y2Xoer3fDHoElGwtxoaDiUkLtX-wxA_Yd0Py7NQnBD10qFfBquGU1ypVNaLCYiY1QPTXMOq9vckU4j2bk3QwuhB_2rfxDOGPHgCebA_wG5T5Z7InsN-k09XH6IvixAahZpLav4YiJcGIgRcSlodPszCuWdpIYimG8rfxI8NKPSIaVJzoJ3_LvFOyZ8spga3ZDCGKoP7mUeKYbe5uEJ4PcCDqtkh1iGg")
      Rails.logger.info "Login successful"
      
      # Check if folder exists
      begin
        Rails.logger.info "Examining folder: #{folder}"
        imap.examine(folder)
        Rails.logger.info "Folder found and accessible"
      rescue Net::IMAP::NoResponseError => e
        Rails.logger.info "Folder not found: #{e.message}"
        # Try to recover by checking available folders
        available_folders = imap.list('', '*').map { |f| f.name }
        folder_suggestion = available_folders.first
        Rails.logger.info "Available folders: #{available_folders.inspect}"

        imap.logout
        imap.disconnect

        Rails.logger.info "IMAP Connection Test result: #{response.inspect}"

        respond_to do |format|
          format.json {
            render json: {
              status: 'error',
              message: l(:error_folder_not_found, folder: folder, suggestion: folder_suggestion)
            }
          }
        end
        return
      end

     Rails.logger.info "IMAP Connection Test result: #{response.inspect}"
      
     # Logout and disconnect
     Rails.logger.info "Test successful, logging out"
     imap.logout
     imap.disconnect
      
      # Return success message

      response = { status: 'success', message: l(:notice_connection_successful) }
      Rails.logger.info "IMAP Connection Test result: #{response.inspect}"

      # Return success message
     respond_to do |format|
         format.json { render json: response }
     end


    rescue => e
      Rails.logger.error "IMAP Connection Error: #{e.class}: #{e.message}"
       Rails.logger.error e.backtrace.join("\n")

          # Create response with detailed error information
          response = {
            status: 'error',
            message: "#{l(:error_connection_failed)}: #{e.message}",
            connection_details: {
              host: host,
              port: port,
              ssl: ssl,
              tls_version: "TLSv1.2",
              folder: folder
            },
            error_class: e.class.to_s
          }

          Rails.logger.info "IMAP Connection Test result: #{response.inspect}"

          # Return error message
          respond_to do |format|
            format.json { render json: response }
          end
        end
  end


  
  def receive_email
    # This method will be called by the email processor when receiving an email
    # It should be protected with an API key or other authentication method
    if request.post?
      from = params[:from]
      to = params[:to]
      subject = params[:subject]
      body = params[:body]
      
      # Get settings
      # Fix: Initialize settings to empty hash if nil
      settings = Setting.plugin_redmine_email_receiver || {}
      project_identifier = settings['default_project']
      
      # Find the project
      project = Project.find_by(identifier: project_identifier)
      
      unless project
        render json: { status: 'error', message: 'Project not found' }, status: :unprocessable_entity
        return
      end
      
      # Find or create user based on email
      user = User.find_by(mail: from)
      
      # If user not found, use admin or anonymous
      user ||= User.admin.first || User.anonymous
      
      # Create the issue
      issue = Issue.new(
        project: project,
        subject: subject,
        description: body,
        author: user
      )
      
      # Set tracker, priority, etc. from settings if available
      issue.tracker_id = Tracker.first.id
      issue.priority_id = IssuePriority.default.id
      
      if issue.save
        render json: { status: 'success', issue_id: issue.id }, status: :created
      else
        render json: { status: 'error', message: issue.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      render json: { status: 'error', message: 'Method not allowed' }, status: :method_not_allowed
    end
  end
  
  def fetch_emails
    # This method can be called manually or via a scheduled task
    # Fix: Initialize settings to empty hash if nil
    settings = Setting.plugin_redmine_email_receiver || {}
    
    # Check if IMAP settings are configured
    if settings['imap_host'].blank? || settings['imap_username'].blank? || settings['imap_password'].blank?
      flash[:error] = l(:error_imap_not_configured)
      redirect_to action: 'index'
      return
    end
    
    begin
      require 'net/imap'
      require 'mail'
      
      host = settings['imap_host']
      port = (settings['imap_port'] || 143).to_i
      ssl = settings['imap_ssl'] == '1'
      username = settings['imap_username']
      password = settings['imap_password']
      folder = settings['imap_folder'] || 'INBOX'
      project_identifier = settings['default_project']
      
      # Connect to IMAP server
      imap = Net::IMAP.new(host, port: port, ssl: ssl)
      
      # Login
      imap.login(username, password)
      
      # Select mailbox
      imap.select(folder)
      
      # Search for unread emails
      message_ids = imap.search(['UNSEEN'])
      
      processed_count = 0
      error_count = 0
      
      # Process each message
      message_ids.each do |message_id|
        begin
          # Fetch email
          msg = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
          mail = Mail.new(msg)
          
          # Extract email information
          from = mail.from.first
          subject = mail.subject || '(No Subject)'
          
          # Get body (prefer plain text, fallback to HTML)
          body = if mail.text_part
                   mail.text_part.body.decoded
                 elsif mail.html_part
                   # Simple HTML to text conversion
                   mail.html_part.body.decoded.gsub(/<\/?[^>]*>/, '')
                 else
                   mail.body.decoded
                 end
                 
          # Create issue
          result = create_issue_from_email(from, subject, body, project_identifier)
          
          if result[:success]
            processed_count += 1
            # Mark as read
            imap.store(message_id, "+FLAGS", [:Seen])
          else
            error_count += 1
            logger.error "Failed to create issue from email: #{result[:message]}"
          end
        rescue => e
          error_count += 1
          logger.error "Error processing email: #{e.message}"
        end
      end
      
      # Logout and disconnect
      imap.logout
      imap.disconnect
      
      flash[:notice] = l(:notice_emails_processed, count: processed_count, errors: error_count)
    rescue => e
      flash[:error] = l(:error_processing_emails, message: e.message)
    end
    
    redirect_to action: 'index'
  end
  
  private
  
  def create_issue_from_email(from, subject, body, project_identifier)
    # Find the project
    project = Project.find_by(identifier: project_identifier)
    
    unless project
      return { success: false, message: "Project not found: #{project_identifier}" }
    end
    
    # Find or create user based on email
    user = User.find_by(mail: from)
    
    # If user not found, use admin or anonymous
    user ||= User.admin.first || User.anonymous
    
    # Create the issue
    issue = Issue.new(
      project: project,
      subject: subject,
      description: body,
      author: user
    )
    
    # Set tracker, priority, etc. from settings if available
    issue.tracker_id = Tracker.first.id
    issue.priority_id = IssuePriority.default.id
    
    if issue.save
      return { success: true, issue_id: issue.id }
    else
      return { success: false, message: issue.errors.full_messages.join(', ') }
    end
  end
end
