defmodule RefreshTokenExampleWeb.Router do
  use RefreshTokenExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RefreshTokenExampleWeb.Guardian.AuthPipeline
  end

  scope "/api", RefreshTokenExampleWeb do
    pipe_through :api

    post "/users", UserController, :create
    post "/sessions", SessionController, :create
    post "/sessions/refresh", SessionController, :refresh
  end

  scope "/api", RefreshTokenExampleWeb do
    pipe_through [:api, :auth]

    get "/protected_resources", ProtectedResourceController, :index
    delete "/sessions/logout_all", SessionController, :delete_all
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:refresh_token_example, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: RefreshTokenExampleWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
