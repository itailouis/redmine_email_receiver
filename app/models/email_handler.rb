class EmailHandler < MailHandler
    def receive(email)
      project = Project.find_by_identifier(get_project_from_email(email))
      return false unless project
  
      # Create a new issue
      issue = Issue.new(
        author: find_user_from_email(email.from.first),
        project: project,
        subject: email.subject,
        description: email.text_part ? email.text_part.body.decoded : email.body.decoded,
        tracker: project.trackers.first
      )
  
      issue.save!
      issue
    end
  
    private
  
    def get_project_from_email(email)
      # Use the default project from settings
      Setting.plugin_redmine_email_receiver['default_project']
    end
  
    def find_user_from_email(email_address)
      user = User.find_by_mail(email_address)
      user || User.anonymous
    end
  end