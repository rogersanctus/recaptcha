defmodule Recaptcha.Csrf.UserAccess do
  use Ecto.Schema
  import Ecto.Changeset
  alias Recaptcha.Csrf.UserAccess
  alias Recaptcha.Csrf.UserAccessInfo

  schema "user_access" do
    field :token, :string
    field :user_info, :string
    field :user_info_map, {:map, UserAccessInfo}, virtual: true
  end

  def changeset(%UserAccess{} = user_access, params \\ %{}) do
    user_access
    |> cast(params, [:token])
    |> fetch_user_info(params)
    |> validate_required([:token, :user_info])
  end

  defp fetch_user_info(changeset, %{"user_info" => user_info} = _params)
       when is_map(user_info) do
    user_info_map =
      user_info
      |> user_info_from_map()

    changeset
    |> put_change(:user_info_map, user_info_map)
    |> put_change(:user_info, Jason.encode!(user_info))
  end

  defp fetch_user_info(changeset, %{"user_info" => user_info} = _params)
       when is_binary(user_info) do
    user_info_map = user_info_from_string(user_info)

    changeset
    |> put_change(:user_info_map, user_info_map)
    |> put_change(:user_info, user_info)
  end

  def user_info_from_string(user_info) when is_binary(user_info) do
    user_info
    |> Jason.decode!()
    |> user_info_from_map()
  end

  def user_info_to_string(%UserAccessInfo{ip: ip} = user_info) do
    ip = normalize_ip!(ip)

    user_info
    |> Map.put(:ip, ip)
    |> Map.delete(:__struct__)
    |> Jason.encode!()
  end

  defp user_info_from_map(%{} = map) do
    map
    |> Enum.reduce(%UserAccessInfo{}, fn {k, v}, acc -> Map.put(acc, String.to_atom(k), v) end)
  end

  defp normalize_ip!(ip) do
    {version, ip} = split_ip(ip)

    ip_terms = Enum.map(ip, fn ip_term -> normalize_ip_term(ip_term) end)

    ip =
      case version do
        :maybe_ipv6 ->
          Enum.join(ip_terms, ":")

        :maybe_ipv4 ->
          Enum.join(ip_terms, ".")
      end

    case :inet.parse_address(to_charlist(ip)) do
      {:ok, ip} ->
        ip
        |> :inet.ntoa()
        |> to_string()

      {:error, _} ->
        throw({:error, "Invalid IP address"})
    end
  end

  defp normalize_ip_term(ip_term) do
    if ip_term == "" do
      ip_term
    else
      ip_term
      |> String.to_integer()
      |> to_string()
    end
  end

  defp split_ip(ip) do
    if String.match?(ip, ~r/:/) do
      {:maybe_ipv6, String.split(ip, ":")}
    else
      {:maybe_ipv4, String.split(ip, ".")}
    end
  end
end
