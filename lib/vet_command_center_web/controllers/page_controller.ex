defmodule VetCommandCenterWeb.PageController do
  use VetCommandCenterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
