defmodule Recaptcha.Csrf.Store.BdStore do
  @behaviour Recaptcha.Csrf.Store.Behaviour

  alias Recaptcha.Repo
  alias Recaptcha.Csrf.UserAccess
  alias Recaptcha.Csrf.UserAccessInfo
  import Ecto.Query, only: [from: 2]

  def put_token(token, user_info) do
    user_info_str = Jason.encode!(user_info)

    %UserAccess{}
    |> UserAccess.changeset(%{"token" => token, "user_info" => user_info_str})
    |> Repo.insert()
  end

  def get_token(%UserAccessInfo{ip: _ip, user_agent: _user_agent} = user_info) do
    user_info = UserAccess.user_info_to_string(user_info)

    record =
      from(UserAccess,
        where: [user_info: ^user_info]
      )
      |> Repo.one()

    case record do
      nil ->
        nil

      %UserAccess{token: token} ->
        token
    end
  end

  def delete_token(%UserAccessInfo{ip: ip, user_agent: user_agent}) do
    from(UserAccess, where: [ip: ^ip, user_agent: ^user_agent])
    |> Repo.delete_all()
  end
end
