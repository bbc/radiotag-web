class RadioTagOmniAuth < Sinatra::Base
  use Rack::Session::Cookie, :expire_after => (60 * 60 * 24 * 21)
  use Rack::Flash

  set :static, true
  set :public, Proc.new { File.join(File.join(File.dirname(__FILE__), "..", "public")) }
  set :method_override => true

  helpers do
    def current_user
      # if :environment == :development
      #   session[:user_id] = 1 # HACK!!!!!
      # end
      @current_user || User.get(session[:user_id]) if session[:user_id]
    end

    def content_for(key, value)
      @content ||= {}
      @content[key] = value
    end

    def content(key)
      @content && @content[key]
    end

    def authenticate!
      redirect '/' unless current_user
    end

    def authenticate_admin!
      redirect '/' unless (current_user && current_user.admin?)
    end

    def current_user_header
      if current_user
        headers('X-RadioTAG-Account-Name' => current_user.name)
      end
    end
  end

  get '/' do
    if current_user
      if current_user.has_authorized_devices?
        redirect '/bookmarks'
      else
        redirect '/device'
      end
    else
      redirect '/login'
    end
  end

  get '/login' do
    erb :login
  end

  get '/help' do
    erb :help
  end

  get '/admin' do
    authenticate_admin!
    current_user_header
    @users = User.all
    erb :admin
  end

  get '/admin/user/:user/devices' do
    authenticate_admin!
    current_user_header
    @user = User.get(params[:user])
    erb :admin_user
  end

  get '/admin/devices/:device/' do
    authenticate_admin!
    current_user_header
    @device = Device.get(params[:device])
    erb :admin_device
  end

  get '/bookmarks' do
    authenticate!
    current_user_header
    if params[:page]
      @page = params[:page].to_i
    else
      @page = 1
    end

    bookmarks_per_page = 10
    @bookmarks = current_user.tags_grouped_by_day(:limit => bookmarks_per_page,
                                                  :offset => (@page - 1) * bookmarks_per_page)
    @number_of_pages = (current_user.tags.count / bookmarks_per_page.to_f).ceil

    erb :bookmarks
  end

  get '/device' do
    authenticate!
    current_user_header
    if current_user.has_authorized_devices?
      erb :register_step_4
    else
      erb :register_step_1, :locals => { :pin_error => params[:pin_error] }
    end
  end

  get '/device/edit' do
    authenticate!
    current_user_header
    erb :register_step_2
  end

  get '/device/pin' do
    authenticate!
    current_user_header
    @pin = session[:pin]
    erb :register_step_3
  end

  delete '/device/:device_id/token' do
    device = Device.get(params[:device_id])
    device.deauthorize!
    redirect "/admin/user/#{device.user_id}/devices"
  end

  post '/devices' do
    begin
      registration_key = params["registration_key"]

      halt 400, "Device ID must not be blank" if registration_key.nil? or registration_key.empty?

      response = AuthService["/assoc"].post(
                                            {:registration_key => registration_key,
                                              :id => current_user.id}
                                            ) { |response, request, reply| response }

      case response.code
      when 201
        json = JSON.parse(response.body)

        device = Device.create(:user_id => current_user.id)
        device.pin  = json["pin"]
        device.save
        session[:pin] = device.pin
        redirect "/device/pin"
      when 400
        halt 400, "This device has already been registered"
      else
        halt response.code, response.body
      end
    rescue => e
      halt 500, "Internal server error\n #{e}"
    end
  end

  get '/session/destroy' do
    session[:user_id] = nil
    redirect '/'
  end

  post '/session/create' do
    name = params[:name]
    password = params[:password]

    user = User.first(:name => name)
    if user and !user.password.nil? and (user.password == password)
      session[:user_id] = user.id
      redirect '/'
    else
      flash[:message] = "Please check your details"
      redirect '/'
    end
  end
end

