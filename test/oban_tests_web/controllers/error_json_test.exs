defmodule ObanTestsWeb.ErrorJSONTest do
  use ObanTestsWeb.ConnCase, async: true

  test "renders 404" do
    assert ObanTestsWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ObanTestsWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
