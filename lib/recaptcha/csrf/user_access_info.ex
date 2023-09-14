defmodule Recaptcha.Csrf.UserAccessInfo do
  @moduledoc false
  use Ecto.Type

  defstruct ip: "", user_agent: ""

  @type t :: %__MODULE__{
          ip: String.t(),
          user_agent: String.t()
        }

  def type() do
    :map
  end

  def cast(%{"ip" => ip, "user_agent" => user_agent}) do
    {
      :ok,
      %__MODULE__{
        ip: ip,
        user_agent: user_agent
      }
    }
  end

  def cast(_), do: :error

  def load(_) do
    {:ok, %__MODULE__{}}
  end

  def dump(_), do: :error
end
