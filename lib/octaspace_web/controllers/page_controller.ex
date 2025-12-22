defmodule OctaspaceWeb.PageController do
  use OctaspaceWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
