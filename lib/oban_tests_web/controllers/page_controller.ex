defmodule ObanTestsWeb.PageController do
  use ObanTestsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
