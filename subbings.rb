
class SheriffApp < Sinatra::Base
  # Fetch a list of existing requests or offers.
  get '/subbings' do 
    login_required!

    mail = @user.mail[0]
    subs = Subbing.actives.where({:object_mail => mail} | {:request => true})
    if accept_json?
      content_type :json
      subs.all.to_json
    else
      requests, offers = subs.all.partition { |s| s.request }
      erb :subbings, :locals => {:requests => requests, :offers => offers}
    end
  end


  # Create a new subbing request or offer.
  post %r{/subbings/(requests|offers)} do |action|
    login_required!

    begin
      day = Date.parse(request['day'].strip, true)
    rescue ArgumentError
      error 400, 'Invalid date'
    end

    subbing = Subbing.new(
      :subject_mail => @user.mail[0], :request => action == 'requests',
      :day_day => day, :comment => request['comment'].strip,
      :object_mail => request['object'] ? request['object'].strip : ''
   ) 
    hash = subbing.calculate_id
    error 400, 'Duplicate subbing' if Subbing.where(:id => hash).count >= 1
    error 500, subbing.inspect

    begin
      subbing.save
    rescue Sequel::ValidationFailed => e
      messages = e.errors.full_messages.join(', ')
      error 400, "Validation failed: #{messages}"
    end

    notify(:create, subbing) if SETTINGS['mail']['enabled']

    status 202 # Created
    if accept_json?
      content_type :json
      subbing.values.to_json
    else
      thing = action[0..-2]
      flash.notice "The #{thing} has been successfully submitted."
      redirect_back
    end
  end


  post '/subbings/offer/accept/:id' do |id|
    offer = Subbing.fetch(:id => id) or error 404, 'No such subbing offer'
    if not offer.directed_to? @user
      error 403, "The specified subbing offer is not directed towards you"
    end

    offer.day.update(:sheriff => offer.subject)
    offer.update(:fulfilled => true)

    notify(:accept, offer) if SETTINGS['mail']['enabled']

    if accept_json?
      content_type :json
    else
      flash.notice "The offer has been accepted."
      redirect_back
    end
  end


  post '/subbings/offer/decline/:id' do |id|
    offer = Subbing.fetch(:id => id) or error 404, 'No such subbing offer'
    if not offer.directed_to? @user
      error 403, "The specified subbing offer is not directed towards you"
    end
    offer.destroy
    notify(:reject, offer) if SETTINGS['mail']['enabled']
  end


  post '/subbings/request/take/:id' do |id|
    req = Subbing.fetch(:id => id) or error 404, 'No such subbing request'

    req.day.update(:sheriff => req.object)
    req.update(:fulfilled => true)

    notify(:accept, req) if SETTINGS['mail']['enabled']

    if accept_json?
      content_type :json
    else
      flash.notice "The request has been taken."
      redirect_back
    end
  end


=begin
  post '/subbings/request/dismiss/:id' do |id|
    req = Subbing.fetch(:id => id) or error 404, 'No such subbing req'
    if not req.directed_to? @user
      error 403, "The specified subbing request is not directed towards you"
    end
    req.destroy
    notify(:reject, req) if SETTINGS['mail']['enabled']
  end
=end

end

