
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
    prefs[pref] = case type
      when String then input
      when Boolean then (input == 'on')
      when Integer then input.to_i
    end
  end
  content_type :plain
  prefs.inspect
end

