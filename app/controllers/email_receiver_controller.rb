# redmine_email_receiver/app/controllers/email_receiver_controller.rb

class EmailReceiverController < ApplicationController
  before_action :require_admin
  layout 'admin'
  
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
      
      # Connect to IMAP server
      imap = Net::IMAP.new(host, port: port, ssl: ssl)
      
      # Login
      imap.login(username, password)
      
      # Check if folder exists
      begin
        imap.examine(folder)
      rescue Net::IMAP::NoResponseError => e
        # Try to recover by checking available folders
        available_folders = imap.list('', '*').map { |f| f.name }
        folder_suggestion = available_folders.first
        
        imap.logout
        imap.disconnect
        
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
      # Return error message
      Rails.logger.info "error Receiver:  #{e.message}"
      respond_to do |format|
        format.json { render json: { status: 'error', message: e.message } }
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