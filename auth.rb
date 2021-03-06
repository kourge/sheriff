require 'net/ldap'


module Auth
  # The DN class responsible for parsing various info out of an email address.
  class DN < Struct.new(:dn, :mail, :o)
    def initialize(mail)
      match = mail.match /^[a-z.]+@(.+?)\.(.+)$/
      o = case [match[1], match[2]]
        when ['mozilla', 'com'], ['mozilla-japan', 'org'] then 'com'
        when ['mozilla', 'org'], ['mozillafoundation', 'org'] then 'org'
        else 'net'
      end
      self.dn = "mail=#{mail},o=#{o},dc=mozilla"
      self.mail = mail
      self.o = o
    end
  end

  def self.ldap_connection
    Net::LDAP.new(
      :host => SETTINGS['ldap']['host'], :port => SETTINGS['ldap']['port']
    )
  end

  # Actually checks credentials using the LDAP server.
  def self.authorized?(username, password)
    return false if not username or not password

    ldap = self.ldap_connection
    ldap.auth(DN.new(username).dn, password)
    ldap.bind # bind returns a boolean
  end
end


class SheriffApp < Sinatra::Base
  helpers do
    def login(username, password)
      return false if not Auth.authorized?(username, password)
      session[:user] = { :mail => username }
      true
    end

    def logout
      session.delete(:user)
      redirect_back
    end

    # Checks if a session matching the cookie for the current user is active.
    def logged_in?
      return false if not session[:user]
      session[:user][:mail] and not session[:user][:mail].empty?
    end

    # Marks a page as authentication required.
    def login_required!
      error 401, 'You need to log in first.' unless logged_in?
    end

    # Populates @user with the LDAP entry of the current user.
    def populate_user(username=nil)
      return if @user
      error 400, 'No user to populate. Contact kourge' if username.nil?

      ldap = Auth.ldap_connection
      ldap.auth(SETTINGS['ldap']['bind_dn'], SETTINGS['ldap']['bind_password'])
      error 500, 'LDAP bind fail. Contact kourge' if not ldap.bind
      filter = Net::LDAP::Filter.eq('mail', Auth::DN.new(username).mail)
      @user = ldap.search(:base => "dc=mozilla", :filter => filter)[0]
    end

    def first_time?(username)
      Sheriff[Auth::DN.new(username).mail].nil?
    end

    def initialize_user(username)
      populate_user(username)
      # Prefill some information.
      sheriff = Sheriff.new(
        :fullname => @user.cn[0], :nick => @user.mail[0].split('@')[0]
      ) { |s| s.mail = @user.mail[0] }.save
    end
  end


  before do
    populate_user(session[:user][:mail]) if logged_in?
  end


  get '/login' do redirect '/' end


  post '/login' do
    username, password = request['username'].strip, request['password']
    succeeded = login(username, password)
    error 401, 'Authentication failed.' if not succeeded
    if first_time? username
      initialize_user(username)
      flash.notice 'Since this is your first time logging in, please take a moment and set your Preferences.'
    end
    redirect_back
  end


  get '/logout' do logout end
  post '/logout' do logout end
end

