class EmailReceiverController < ApplicationController
  before_action :require_admin

  private

  def load_settings
    config_file = File.join(Rails.root, 'plugins', 'redmine_email_receiver', 'config', 'settings.yml')
    if File.exist?(config_file)
      YAML.load_file(config_file)['email_settings'] || {}
    else
      {}
    end
  end

  def test_connection
    begin
      settings = load_settings
      imap_settings = {
        host: settings['imap_host'],
        port: settings['imap_port'].to_i,
        ssl: settings['imap_ssl'] == '1',
        username: settings['imap_username'],
        password: settings['imap_password']
      }

      require 'net/imap'
      imap = Net::IMAP.new(imap_settings[:host], imap_settings[:port], imap_settings[:ssl])
      imap.login(imap_settings[:username], imap_settings[:password])
      imap.select(settings['imap_folder'])
      imap.disconnect

      flash[:notice] = l(:notice_email_settings_successful)
      status = 'success'
    rescue => e
      flash[:error] = l(:error_email_settings_connection, message: e.message)
      status = 'error'
    end

    render json: { status: status, message: flash[:error] || flash[:notice] }
  end
end