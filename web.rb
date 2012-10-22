require 'sinatra'
require 'json'
require 'active_support/core_ext'
require 'oauth'
require 'omniauth'
require 'omniauth-tumblr'
require 'tumblife'

enable :sessions

use OmniAuth::Builder do
  provider :tumblr, ENV['TUMBLR_KEY'], ENV['TUMBLR_SECRET']
end

set :user_informations, {}
set :icons, {}

helpers do
  def sign_in(auth)
    session[:token]  = @auth["credentials"]["token"]
    session[:secret] = @auth["credentials"]["secret"]
  end

  def signed_in?
    session[:token] and session[:secret]
  end

  def base_hostname(short_name)
    "#{short_name}.tumblr.com"
  end

  def primary_short_name
    info.user.blogs.select(&:primary).first.name
  end

  def info
    settings.user_informations[session[:token]] ||= @client.info
  end

  def primary_base_hostname
    base_hostname(primary_short_name)
  end

  def icon(base_hostname)
    settings.icons[base_hostname] ||=
    begin
      @client.avatar(base_hostname).avatar_url
    rescue => e
      p e
      favicon
    end
  end

  def favicon
    'http://www.tumblr.com/favicon.ico'
  end
end

# if signed in, setup tumblr client
before do
  if signed_in?
    @client = Tumblife.client({
      consumer_key:       ENV['TUMBLR_KEY'],
      consumer_secret:    ENV['TUMBLR_SECRET'],
      oauth_token:        session[:token],
      oauth_token_secret: session[:secret]
    })
  end
end

get '/' do
  if signed_in?
    erb :index
  else
    erb :landing
  end
end

get '/icon/:hostname' do
  if signed_in?
    redirect to icon(params['hostname'])
  else
    redirect to favicon
  end
end

# signed in required pages
before '/photos' do
  redirect to('/') unless signed_in?
end

post '/photos/:hostname' do
  data = params['data'].map {|d|
    Faraday::UploadIO.new(d[:tempfile], d[:type])
  }

  content_type :json
  begin
    data.each {|d| @client.photo(params['hostname'], data: d) }
    {success: true}
  rescue => e
    p e
    {success: false}
  end.to_json
end

get '/signout' do
  settings.user_informations[session[:token]] = nil if session[:token]
  session.clear
  redirect to('/')
end

get '/auth/:provider/callback' do
  @auth = request.env['omniauth.auth']
  sign_in @auth
  redirect to('/')
end

get '/main.js' do
  coffee :main
end

get '/style.css' do
  scss :style
end
