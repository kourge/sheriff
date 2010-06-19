
# Modified from: http://github.com/daigoto/rack-session-sequel

require 'rack/session/abstract/id'

module Rack
  module Session
    # Rack::Session::Sequel provides simple cookie based session management.
    # Session data is stored in database. The corresponding session key is
    # maintained in the cookie. It is based on Rack::Session::Memcache and is
    # compatible with it.

    class Sequel < Abstract::ID
      attr_reader :mutex, :dataset
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge :drop => false

      def initialize(app, options={})
        super
        @mutex = Mutex.new
        if options.key?(:db) and options.key?(:table)
          @db, @table = options[:db], options[:table]
        else
          raise 'No Sequel Dataset'
        end
      end
      
      def dataset
        (@db.respond_to?(:call) ? @db.call : @db)[@table]
      end

      def generate_sid
        loop do
          sid = super
          break sid unless self.dataset.filter('sid = ?', sid).first
        end
      end

      def get_session(env, sid)
        if sid
          data = self.dataset.filter('sid = ?', sid).first
          session = Marshal.load(data[:session].unpack("m*").first) if data
        end
        @mutex.lock if env['rack.multithread']
        unless sid and session
          env['rack.errors'].puts("Session '#{sid.inspect}' not found, initializing...") if $VERBOSE and not sid.nil?
          session = {}
          sid = generate_sid
          self.dataset.insert(
            :sid       => sid,
            :session   => [Marshal.dump(session)].pack('m*'),
            :timestamp => Time.now
          )
        end
        session.instance_variable_set('@old', {}.merge(session))
        return [sid, session]
      rescue 
        warn $!.inspect
        return [ nil, {} ]
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def set_session(env, session_id, new_session, options)
        expiry = options[:expire_after]
        expiry = expiry.nil? ? 0 : expiry + 1

        @mutex.lock if env['rack.multithread']
        data = self.dataset.filter('sid = ?', session_id).first
        session = {}
        if data[:session]
          session = Marshal.load(data[:session].unpack("m*").first) 
        end
        if options[:renew] or options[:drop]
          self.dataset.filter('sid = ?', session_id).delete if data
          return false if options[:drop]
          session_id = generate_sid # change new session_id
          renew_session = {}
          self.dataset.insert(
            :sid       => session_id,
            :session   => [Marshal.dump(renew_session)].pack('m*'),
            :timestamp => Time.now
          )
        end
        old_session = new_session.instance_variable_get('@old') || {}
        session = merge_sessions session_id, old_session, new_session, session
        self.dataset.filter('sid = ?', session_id).update(
          :session   => [Marshal.dump(session)].pack('m*'),
          :timestamp => Time.now
        )
        return session_id
      rescue 
        warn $!.inspect
        return false
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      private

      def merge_sessions sid, old, new, cur=nil
        cur ||= {}
        unless Hash === old and Hash === new
          warn 'Bad old or new sessions provided.'
          return cur
        end

        delete = old.keys - new.keys
        warn "//@#{sid}: delete #{delete*','}" if $VERBOSE and not delete.empty?
        delete.each{|k| cur.delete k }

        update = new.keys.select{|k| new[k] != old[k] }
        warn "//@#{sid}: update #{update*','}" if $VERBOSE and not update.empty?
        update.each{|k| cur[k] = new[k] }
        cur
      end
    end
  end
end

use Rack::Session::Sequel, :key => 'rack.session', :db => $db, :table => :sessions

