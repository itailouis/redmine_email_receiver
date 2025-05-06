namespace :redmine do
  namespace :email do
    desc 'Receive emails from IMAP server and create issues'
    task :innovation_mail_task => :environment do
      imap_settings = {
        host: Setting.plugin_redmine_email_receiver['imap_host'],
        port: Setting.plugin_redmine_email_receiver['imap_port'].to_i,
        ssl: Setting.plugin_redmine_email_receiver['imap_ssl'] == '1',
        username: Setting.plugin_redmine_email_receiver['imap_username'],
        password: Setting.plugin_redmine_email_receiver['imap_password'],
        folder: Setting.plugin_redmine_email_receiver['imap_folder']
}

      with_imap_connection(imap_settings) do |imap|
        imap.search(['NOT', 'SEEN']).each do |message_id|
          msg = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
          email = Mail.new(msg)
          
          handler = EmailHandler.new
          if handler.receive(email)
            # Mark message as seen
            imap.store(message_id, "+FLAGS", [:Seen])
          end
        end
      end
    end

    def with_imap_connection(settings)
      require 'net/imap'
      imap = Net::IMAP.new(settings[:host], settings[:port], settings[:ssl])
      imap.login(settings[:username], settings[:password])
      imap.select(settings[:folder])
      yield imap
      imap.disconnect
    end
  end
end