require 'sinatra'
require 'dm-core'
require 'builder'
require 'dm-validations' 
require "dm-paginator"

require 'facets/date'

Date::FORMAT[:only_date] = '%d.%m.%y'  # For Date objects
Time::FORMAT[:only_date] = '%d.%m.%y'  # For DateTime objects

helpers do

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
  end

end

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

# Create your model class
class Shout
  include DataMapper::Resource

  property :id, Serial
  property :user, String
  property :body, Text
  property :reply, Text
  property :created_at, DateTime
  
  # before :save do
  #     self.created_at = Time.now
  # end
end

# Main board
get '/' do
  protected!
  # Just list all the shouts
  #@shouts = Shout.paginate(:order => [:created_at.desc], :per_page => 10, :page => params[:page])
  @shouts = Shout.limit_page  params[:page], :limit => 10, :page => params[:page]
  
  page_html = ""
  puts "#{@shouts.paginator.count} / #{@shouts.paginator.count / 10}"
  (@shouts.paginator.count / 10 + 1).times do | page |
    page_html += "<a href='?page=#{page+1}'>#{page+1}</a> &nbsp;"
  end
  @pager = page_html
  erb :index
end

get '/gb.xml' do
  @shouts = Shout.limit_page 1, :limit => 10
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    @shouts.each do |post|
      xml.item do
        xml.id post.id
        xml.user post.user
        xml.body post.body
        xml.reply post.reply
        xml.pubDate post.created_at.stamp(:only_date)
      end
    end    
  end
end

post '/' do
  # Create a now shout and redirect back to the list
  shout = Shout.create(:user => params[:user], :body => params[:body], :created_at => Time.now  )
  redirect '/'
end

get '/:id' do
  # Create a now shout and redirect back to the list
  @gb = Shout.get params[:id]
  erb :edit
end

post '/update' do
  # Create a now shout and redirect back to the list
  @gb = Shout.get params[:id]
  @gb.reply = params[:reply]
  @gb.save
  redirect '/'
end

get '/delete/:id' do
  # Create a now shout and redirect back to the list
  shout = Shout.get params[:id]
  shout.destroy
  redirect '/'
end