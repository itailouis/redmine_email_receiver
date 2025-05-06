require 'redmine'

Redmine::Plugin.register :redmine_email_receiver do
  name 'Redmine Email Receiver plugin'
  author 'itai zulu'
  description 'A plugin to receive emails and create issues'
  version '0.0.1'

  settings default: {
    'imap_host' => '10.170.10.202',
    'imap_port' => '25',
    'imap_ssl' => '0',
    'imap_username' => 'Innovation@fbc.co.zw',
    'imap_password' => '',
    'imap_folder' => 'INBOX',
    'default_project' => 'innovertion'
  }, partial: 'settings/email_receiver_settings'
end