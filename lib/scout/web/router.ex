defmodule Scout.Web.Router do
  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", Scout.Web do
    pipe_through(:api)

    post("/surveys", SurveyController, :create)
    get("/surveys/:id", SurveyShowPlug, :show, as: :survey)
  end
end
