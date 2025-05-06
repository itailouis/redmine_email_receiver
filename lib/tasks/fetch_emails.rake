namespace :redmine do
    namespace :email_receiver do
      desc 'Fetch emails from an IMAP server and create issues'
      task :fetch => :environment do
        require 'net/imap'
        require 'mail'
        
        # Get settings
        settings = Setting.plugin_redmine_email_receiver
        
        # Check if mail settings are configured
        unless settings['imap_host'].present? && settings['imap_port'].present?
          puts "Error: IMAP settings not configured"
          next
        end
        
        begin
          # Connect to IMAP server
          imap = Net::IMAP.new(
            settings['imap_host'], 
            port: settings['imap_port'].to_i, 
            ssl: settings['imap_ssl'] == '1'
          )
          
          # Login
          imap.login(settings['imap_username'], settings['imap_password'])
          
          # Select mailbox
          mailbox = settings['imap_mailbox'] || 'INBOX'
          imap.select(mailbox)
          
          # Search for unread emails
          search_criteria = settings['imap_search_criteria'] || 'UNSEEN'
          message_ids = imap.search([search_criteria])
          
          puts "Found #{message_ids.size} messages to process"
          
          # Process each message
          message_ids.each do |message_id|
            begin
              # Fetch the email
              msg = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
              mail = Mail.new(msg)
              
              # Extract email data
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
              
              # Process attachments
              attachments = []
              if mail.attachments.any?
                mail.attachments.each do |attachment|
                  next if attachment.content_type.start_with?('text/html') # Skip HTML parts
                  
                  attachments << {
                    filename: attachment.filename,
                    content_type: attachment.content_type,
                    content: attachment.body.decoded
                  }
                end
              end
              
              # Create issue from email
              result = EmailProcessor.new.process(
                from: from,
                subject: subject,
                body: body,
                attachments: attachments
              )
              
              if result[:success]
                puts "Created issue ##{result[:issue_id]} from email: #{subject}"
                
                # Mark as processed
                if settings['mark_as_read'] == '1'
                  imap.store(message_id, "+FLAGS", [:Seen])
                end
                
                # Move to processed folder if configured
                if settings['move_processed'] == '1' && settings['processed_folder'].present?
                  imap.copy(message_id, settings['processed_folder'])
                  imap.store(message_id, "+FLAGS", [:Deleted])
                end
              else
                puts "Failed to create issue from email: #{result[:message]}"
                
                # Mark as failed
                if settings['mark_failed'] == '1'
                  imap.store(message_id, "+FLAGS", [:Flagged])
                end
                
                # Move to failed folder if configured
                if settings['move_failed'] == '1' && settings['failed_folder'].present?
                  imap.copy(message_id, settings['failed_folder'])
                  imap.store(message_id, "+FLAGS", [:Deleted])
                end
              end
            rescue => e
              puts "Error processing message #{message_id}: #{e.message}"
            end
          end
          
          # Expunge deleted messages
          imap.expunge
          
          # Logout and disconnect
          imap.logout
          imap.disconnect
          
          puts "Email processing completed"
        rescue => e
          puts "Error connecting to mail server: #{e.message}"
        end
      end
  
      desc 'Setup scheduled email fetching using whenever gem'
      task :setup_schedule => :environment do
        require 'whenever'
        
        # Get settings
        settings = Setting.plugin_redmine_email_receiver
        frequency = settings['fetch_frequency'] || 'hourly'
        
        # Generate schedule.rb content
        schedule_content = <<-SCHEDULE
  # Email Receiver Plugin Schedule
  #{frequency} do
    rake "redmine:email_receiver:fetch"
  end
        SCHEDULE
        
        # Write to schedule file
        schedule_path = File.join(Rails.root, 'plugins', 'redmine_email_receiver', 'config', 'schedule.rb')
        File.write(schedule_path, schedule_content)
        
        # Update crontab
        system("cd #{Rails.root} && whenever --update-crontab redmine_email_receiver --load-file #{schedule_path}")
        
        puts "Email fetching schedule updated (#{frequency})"
      end
    end
  end