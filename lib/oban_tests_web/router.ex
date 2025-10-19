defmodule ObanTestsWeb.Router do
  use ObanTestsWeb, :router

  import Phoenix.LiveDashboard.Router
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ObanTestsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ObanTestsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ObanTestsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development    # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).

  scope "/admin" do
    pipe_through :browser

    live_dashboard "/dashboard",
      metrics: ObanTestsWeb.Telemetry,
      ecto_repos: [ObanTests.Repo],
      ecto_psql_extras_options: [long_running_queries: [threshold: "200 milliseconds"]]

    oban_dashboard("/oban")
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:oban_tests, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      # live_dashboard "/dashboard",
      #   metrics: ObanTestsWeb.Telemetry,
      #   ecto_repos: [ObanTests.Repo],
      #   ecto_psql_extras_options: [long_running_queries: [threshold: "200 milliseconds"]]

      # oban_dashboard("/oban")
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
