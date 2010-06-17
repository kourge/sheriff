require 'net/ldap'
require 'digest'
require 'openssl'

class String
  def aes(operation, key, message)
    aes = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(operation)
    aes.key = OpenSSL::Digest::SHA256.digest(key)
    aes.update(message) << aes.final
  end

  def encrypt(algorithm, key) self.send(algorithm, :encrypt, key, self) end
  def decrypt(algorithm, key) self.send(algorithm, :decrypt, key, self) end

  def md5; Digest::MD5.hexdigest(self) end
end

SECRET = 'Remove me later'
helpers do
  def login(username, password)
    if authorized?(username, password)
      username = username.encrypt :aes, SECRET
      session[:user] = {
        :dn => username,
        :password => password.encrypt(:aes, SECRET),
        :checksum => username.md5
      }
      return true
    end
    return false
  end

  def logout
    session.delete(:user)
    redirect_back
  end

  def logged_in?
    if session[:user]
      user = session[:user][:dn].decrypt(:aes, SECRET)
      password = session[:user][:password].decrypt(:aes, SECRET)
      checksum = session[:user][:dn].md5
      return false if session[:user][:checksum] != checksum
      if not @user
        authorized? user, password
      end
      return true
    end
    return false
  end

  def login_required!
    error 401, 'You need to log in first.' unless logged_in?
  end

  def authorized?(username, password)
    return false if not username or not password
    @mail = username
    match = @mail.match /^[a-z]+@(.+?)\.(.+)$/
    o = match.nil? ? 'com' : case [match[1], match[2]]
      when %w(mozilla com), %w(mozilla-japan org)
        'com'
      when %w(mozilla org), %w(mozillafoundation org)
        'org'
      else
        'net'
    end
    @mail += '@mozilla.com' if match.nil?

    ldap = Net::LDAP.new(
      :host => SETTINGS['ldap']['host'], :port => SETTINGS['ldap']['port']
    )
    ldap.auth("mail=#{@mail},o=#{o},dc=mozilla", password)
    # ldap.auth(SETTINGS['ldap']['bind_user'], SETTINGS['ldap']['bind_password'])
    if ldap.bind
      filter = Net::LDAP::Filter.eq('mail', @mail)
      @user = ldap.search(:base => "o=#{o},dc=mozilla", :filter => filter)[0]
      return true
    end
    false
  end
end

before do
  # Populate the @user object.
  logged_in?
end

get '/login' do redirect '/' end

post '/login' do
  succeeded = login(request['username'], request['password'])
  error 401, 'Authentication failed.' if not succeeded
  redirect_back
end

get '/logout' do logout end
post '/logout' do logout end

