defmodule Scout.Web.Router do
  use Scout.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Scout.Web do
    pipe_through :api

    post "/surveys", SurveyController, :create
  end
end
