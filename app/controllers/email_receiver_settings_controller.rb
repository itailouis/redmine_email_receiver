class EmailReceiverSettingsController < ApplicationController
  layout 'admin'
  before_action :require_admin

  def load_settings
    config_file = File.join(Rails.root, 'plugins', 'redmine_email_receiver', 'config', 'settings.yml')
    Rails.logger.info "Email Receiver: Loading settings from #{config_file}"
    
    settings = if File.exist?(config_file)
      YAML.load_file(config_file)['email_settings'] || default_settings
    else
      default_settings
    end
    
    Rails.logger.info "Email Receiver: Loaded settings: #{settings.inspect}"
    settings
  end

  def save_settings
    settings = params[:settings].to_unsafe_h
    config_file = settings_file_path
    
    begin
      FileUtils.mkdir_p(File.dirname(config_file))
      config = { 'email_settings' => settings }
      File.write(config_file, config.to_yaml)
      Setting.clear_cache # Clear Redmine's settings cache
      
      render json: { 
        status: 'success', 
        message: l(:notice_successful_update)
      }
    rescue => e
      Rails.logger.error "Failed to save settings: #{e.message}"
      render json: {
        status: 'error',
        message: l(:error_settings_save_failed, message: e.message)
      }
    end
  end

  private

  def default_settings
    {
      'imap_host' => '',
      'imap_port' => '25',
      'imap_ssl' => '0',
      'imap_username' => '',
      'imap_password' => '',
      'imap_folder' => 'INBOX',
      'default_project' => ''
    }
  end

  def plugin_settings_controller?
    true
  end
end