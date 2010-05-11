require 'sinatra'
require 'dm-core'

require 'dm-core'
require 'dm-pagination'
require 'dm-pagination/paginatable'

require 'facets/date'

Date::FORMAT[:only_date] = '%d.%m.%y'  # For Date objects
Time::FORMAT[:only_date] = '%d.%m.%y'  # For DateTime objects

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

DataMapper::Model.append_extensions DmPagination::Paginatable

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

def pagination_links(collection)
  html = [""]
  if collection.page > 1
    html << "<a href='?page=1'>&lt;&lt;</a>"
    html << "<a href='?page=#{collection.page - 1}'>&lt;</a>"
  end
  (1..collection.num_pages).each do |page|
    if page == collection.page
      html << "<span style='font-weight: bold;'>#{ page}</span>"
    else
      html << "<a href='?page=#{page}'>#{page}</a>"
    end
  end
  if collection.page < collection.num_pages
    html << "<a href='?page=#{collection.page + 1}'>&gt;</a>"
    html << "<a href='?page=#{collection.num_pages}'>&gt;&gt;</a>"
  end
  html.join(' ')
end


# Main board
get '/' do
  # Just list all the shouts
  @shouts = Shout.paginate(:order => [:created_at.desc], :per_page => 10, :page => params[:page])
  erb :index
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