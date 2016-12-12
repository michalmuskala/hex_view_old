defmodule HexView.Web.Router do
  use HexView.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :files do
    plug :accepts, ["text"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HexView.Web do
    pipe_through :files

    get "/raw/:package/:version", FileController, :index
    get "/raw/:package/:version/*path", FileController, :show
  end

  scope "/", HexView.Web do
    pipe_through :browser

    get "/", PageController, :index
    get "/packages/:package/:version", FileController, :index
    get "/packages/:package/:version/*path", FileController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", HexView do
  #   pipe_through :api
  # end
end
