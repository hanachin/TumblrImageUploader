require "rack-canonical-host"
require "./web.rb"

use Rack::CanonicalHost, 'tiu.hanach.in'

run Sinatra::Application
