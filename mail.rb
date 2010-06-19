
require 'pony'

helpers do
  def notify(action, subbing)
    case action
      when :create then notify_create(subbing)
      when :accept then
        notify_accept(subbing) if subbing.subject.email_notifications
      when :reject then
        notify_reject(subbing) if subbing.subject.email_notifications
    end
  end


  def notify_create(subbing)
    date = subbing.day.strftime '%A, %B %d, %Y'
    if subbing.request
      # Notify everyone who allow mail.
      Sheriff.where(:email_notifications => true).each do |sheriff|
        Pony.mail(
          :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
          :subject => "Sheriff sub needed on #{date}",
          :body => erb(:'mail/request_directed', :layout => false, :locals => {
            :request => subbing
          })
        )
      end
    else
      # This is an offer.
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
        :subject => "Offer to sub as sheriff on #{date}",
        :body => erb(:'mail/offer_extended', :layout => false, :locals => {
          :offer => subbing
        })
      ) if object.subject.email_notifications
    end
  end


  def notify_accept(subbing)
    if subbing.request
      # Notify original requester of this taking
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
        :subject => "",
        :body => erb(:'mail/request_taken', :layout => false, :locals => {
          :request => subbing
        })
      )
    else
      # Notify original offerer of this acceptance
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
        :subject => "",
        :body => erb(:'mail/offer_accepted', :layout => false, :locals => {
          :offer => subbing
        })
      )
    end
  end


  def notify_reject(subbing)
    if subbing.request
      # Notify original requester of this dismissal
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
        :subject => "",
        :body => erb(:'mail/request_dismissed', :layout => false, :locals => {
          :request => subbing
        })
      )
    else
      # Notify original offerer of this declination
      Pony.mail(
        :from => SETTINGS['mail']['from'], :to => subbing.subject.mail,
        :subject => "",
        :body => erb(:'mail/offer_declined', :layout => false, :locals => {
          :offer => subbing
        })
      )
    end
  end
end

