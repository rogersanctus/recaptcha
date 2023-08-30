defmodule Recaptcha.Validator do
  @moduledoc """
  Helps on validations.
  The module is completely agnostic on the inputs types and behaviours.
  All it needs for a validation is a key to identify an error and a function
  to actually do the validation. That function must return a string with the
  message about the error, when there is an error, or true when the input is
  valid. 
  """

  defstruct errors_count: 0, errors: [], stop_on_error: false

  @typedoc """
  The validator struct
  """
  @type t :: %__MODULE__{
          errors_count: non_neg_integer(),
          errors: list(),
          stop_on_error: boolean()
        }

  @typedoc """
  The validation function that will be called to validate the input.
  It is a 0 arity function and must return a String or true.
  """
  @type validator_cb :: (-> String.t() | true)

  @doc """
    Uses the `validator_fn` to validate the input. When the return of it is
    true, no error is set. Otherwise, an error is set as a map with `error_key` as
    `key` and the function return as `message`.
  """
  @spec validate(t(), String.t() | atom(), validator_cb()) :: t()
  def validate(%__MODULE__{errors_count: 0} = validator, error_key, validator_fn) do
    do_validate(validator, error_key, validator_fn)
  end

  def validate(%__MODULE__{stop_on_error: true} = validator, _error_key, _validator_fn) do
    validator
  end

  def validate(%__MODULE__{stop_on_error: false} = validator, error_key, validator_fn) do
    do_validate(validator, error_key, validator_fn)
  end

  defp do_validate(validator, error_key, validator_fn) when is_function(validator_fn) do
    errors = validator.errors
    error_message = validator_fn.()

    if error_message != true do
      errors = [
        %{key: error_key, message: error_message} | errors
      ]

      %__MODULE__{validator | errors: errors, errors_count: validator.errors_count + 1}
    else
      validator
    end
  end

  @doc "Check if there are errors in the validator"
  @spec has_errors?(t()) :: boolean()
  def has_errors?(validator) do
    validator.errors_count > 0
  end
end
