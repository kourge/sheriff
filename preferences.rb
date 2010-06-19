
get '/preferences' do
  login_required!
  erb :preferences
end


post '/preferences' do
  login_required!
  prefs = {
    :fullname => String, :nick => String,
    :email_notifications => Boolean, :upcoming_duty_notifications => Boolean,
    :days_in_advance_for_upcoming_duty => Integer
  }
  prefs.each do |pref, type|
    input = request[pref.to_s]
    prefs[pref] = {
      String => lambda { input },
      Boolean => lambda { (input == 'on') },
      Integer => lambda { input.to_i }
    }[type].call
  end
  Sheriff[@user.mail[0]].update(prefs)

  if accept_json?
    content_type :json
    { :success => true }.to_json
  else
    redirect_back
  end
end

