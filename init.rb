require 'redmine'

def load_settings
    config_file = File.join(File.dirname(__FILE__), 'config', 'settings.yml')
    if File.exist?(config_file)
      YAML.load_file(config_file)['email_settings']
    else
      # Default settings if config file doesn't exist
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
end

Redmine::Plugin.register :redmine_email_receiver do
  name 'Redmine Email Receiver plugin'
  author 'itai zulu'
  description 'A plugin to receive emails and create issues'
  version '0.0.1'

  settings default: load_settings, partial: 'settings/email_receiver_settings'
end