require 'active_record'
require 'logger'
require 'yaml'
require 'uri'

module ActiveRecord
  class Base
    class << self
      alias :old_connection :connection
      def connection
        self.clear_active_connections!
        old_connection
      end
    end
  end
end

if ENV['DATABASE_URL']
  db = URI.parse(ENV['DATABASE_URL'])
  ActiveRecord::Base.establish_connection(
    :adapter  => db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8',
    :min_messages => 'notice'
  )
else
  dbconfig = YAML.load_file(File.dirname(__FILE__) + '/config/database.yml')
  ActiveRecord::Base.establish_connection(dbconfig)
end

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/log/database.log')
ActiveRecord::Base.default_timezone = :local

class Timecards < ActiveRecord::Base
end

class ValidationError < StandardError; end
