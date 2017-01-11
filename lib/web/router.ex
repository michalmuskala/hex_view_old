defmodule HexView.Web.Router do
  use HexView.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :raw do
    plug :accepts, ["text"]
  end

  scope "/api", HexView.Web, as: :api do
    pipe_through :raw

    get "/", ApiController, :index
    get "/packages/:package/:version", FileController, :index
    get "/files/:package/:version/*path", FileController, :show
  end

  scope "/", HexView.Web do
    get "/", ElmController, :index
    get "/packages/:package/:version/*data", ElmController, :package
  end
end
