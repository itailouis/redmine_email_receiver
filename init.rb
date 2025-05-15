require 'redmine'

plugin_root = File.dirname(__FILE__)
if File.exist?(File.join(plugin_root, 'Gemfile'))
  require 'bundler'
  begin
    # Load gems from the plugin's Gemfile
    Bundler.setup(:default)
    # Add the plugin's vendor/bundle directory to the load path
    $LOAD_PATH.unshift(File.join(plugin_root, 'vendor/bundle'))
  rescue Bundler::GemNotFound => e
    Rails.logger.error "Bundler couldn't find some gems for redmine_email_receiver: #{e.message}"
    puts "Error: Some gems are missing. Run 'bundle install' in the plugin directory."
  end
end

# Now require the kiota gems
begin
  require 'microsoft_kiota_authentication_oauth'
rescue LoadError => e
  Rails.logger.error "Could not load microsoft_kiota_authentication_oauth: #{e.message}"
end

def load_settings
    config_file = File.join(File.dirname(__FILE__), 'config', 'settings.yml')
    unless File.exist?(config_file)
      File.open(config_file, 'w') { |f| f.write("---\n") }
      File.chmod(0666, config_file)  # Make writable
    end

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
    Rails.logger.info "Email Receiver: Loading settings from #{config_file}"
end

Redmine::Plugin.register :redmine_email_receiver do
  name 'Redmine Email Receiver plugin'
  author 'itai zulu'
  description 'A plugin to receive emails and create issues'
  version '0.0.1'

  settings default: load_settings,
           partial: 'settings/email_receiver_settings'
end
