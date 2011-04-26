# encoding: utf-8
require "bundler/setup"
Bundler.require :production

class SpikeMiddleware < Sinatra::Base
  attr_reader :app, :request, :login_path, :logout_path, :authenticator,
              :logged_in

  def initialize(app, login_path, logout_path, authenticator, logged_in)
    @app            = app
    @login_path     = login_path
    @logout_path    = logout_path
    @authenticator  = authenticator
    @logged_in      = logged_in
  end

  def call(env)
    @request = Rack::Request.new(env)
    case env["PATH_INFO"]
      when login_path then request.get? ? authenticate : app.call(env)
      when logout_path then session.clear && redirect_to_login
      else authenticated? ? app.call(env) : redirect_to_login
    end
  end

  def authenticate
    authenticator.call(request)
  end

  def authenticated?
    logged_in.call(request)
  end

  def redirect_to_login
    [
      302, 
      {"Location" => login_path, "Content-Type" => "text/html"},
      ["Please authenticate"]
    ]
  end
end

class Spike < Sinatra::Base
  enable :sessions
  use SpikeMiddleware, "/login", "/logout", 
        Proc.new { |request| 
          request.session["authenticated"] = true 
          [302, { "Location" => "/protected", "Content-Type" => "text/html"},
          ["Redirecting ..."]]
        },
        Proc.new { |request| request.session["authenticated"] }

  get "/login" do
    "logging in"
  end

  get "/home" do
    "You're home"
  end

  get "/protected" do
    session["authenticated"]
  end
end
