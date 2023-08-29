defmodule RecaptchaWeb.FormJSON do
  def post(%{email: email}) do
    %{
      status: "saved",
      email: email
    }
  end
end
