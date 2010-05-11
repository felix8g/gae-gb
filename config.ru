require 'appengine-rack'
require 'guestbook'

AppEngine::Rack.configure_app(:application => "earthquake-gb", :version => 1)

configure :development do
  class Sinatra::Reloader < ::Rack::Reloader
    def safe_load(file, mtime, stderr)
      if File.expand_path(file) == File.expand_path(::Sinatra::Application.app_file)
        ::Sinatra::Application.reset!
        stderr.puts "#{self.class}: reseting routes"
      end
      super
    end
  end
  use Sinatra::Reloader
end

run Sinatra::Application