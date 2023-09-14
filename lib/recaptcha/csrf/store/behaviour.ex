defmodule Recaptcha.Csrf.Store.Behaviour do
  @moduledoc false

  alias Recaptcha.Csrf.UserAccessInfo

  @callback put_token(token :: String.t(), user_info :: UserAccessInfo.t()) ::
              {:ok, String.t()} | {:error, term()}

  @callback get_token(user_info :: UserAccessInfo.t()) :: String.t() | nil

  @callback delete_token(user_info :: UserAccessInfo.t()) :: {:ok, String.t()} | {:error, term()}
end
