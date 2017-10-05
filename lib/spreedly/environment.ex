defmodule Spreedly.Environment do

  defstruct [ :environment_key, :access_secret ]

  import Spreedly.URL
  import Spreedly.RequestBody

  def new(environment_key, access_secret) do
    %Spreedly.Environment{environment_key: environment_key, access_secret: access_secret}
  end

  def add_gateway(env, gateway_type) do
    HTTPoison.post(add_gateway_url(), add_gateway_body(gateway_type), headers(env))
    |> response
  end

  def add_receiver(env, receiver_type, options \\ []) do
    HTTPoison.post(add_receiver_url(), add_receiver_body(receiver_type, options), headers(env))
    |> response
  end

  def add_credit_card(env, options) do
    HTTPoison.post(add_payment_method_url(), add_credit_card_body(options), headers(env))
    |> response
  end

  def retain_payment_method(env, token) do
    HTTPoison.put(retain_payment_method_url(token), empty_body(), headers(env))
    |> response
  end

  def redact_payment_method(env, token) do
    HTTPoison.put(redact_payment_method_url(token), empty_body(), headers(env))
    |> response
  end

  def store_payment_method(env, gateway_token, payment_method_token) do
    HTTPoison.post(store_payment_method_url(gateway_token), store_payment_method_body(payment_method_token), headers(env))
    |> response
  end

  def purchase(env, gateway_token, payment_method_token, amount, currency_code \\ "USD", options \\ []) do
    HTTPoison.post(purchase_url(gateway_token), auth_or_purchase_body(payment_method_token, amount, currency_code, options), headers(env))
    |> response
  end

  def authorization(env, gateway_token, payment_method_token, amount, currency_code \\ "USD", options \\ []) do
    HTTPoison.post(authorization_url(gateway_token), auth_or_purchase_body(payment_method_token, amount, currency_code, options), headers(env))
    |> response
  end

  def capture(env, transaction_token) do
    HTTPoison.post(capture_url(transaction_token), empty_body(), headers(env))
    |> response
  end

  def void(env, transaction_token) do
    HTTPoison.post(void_url(transaction_token), empty_body(), headers(env))
    |> response
  end

  def credit(env, transaction_token) do
    HTTPoison.post(credit_url(transaction_token), empty_body(), headers(env))
    |> response
  end

  def verify(env, gateway_token, payment_method_token, currency_code \\ nil, options \\ []) do
    HTTPoison.post(verify_url(gateway_token), verify_body(payment_method_token, currency_code, options), headers(env))
    |> response
  end

  def show_gateway(env, gateway_token) do
    HTTPoison.get(show_gateway_url(gateway_token), headers(env))
    |> response
  end

  def show_receiver(env, receiver_token) do
    HTTPoison.get(show_receiver_url(receiver_token), headers(env))
    |> response
  end

  def show_payment_method(env, payment_method_token) do
    HTTPoison.get(show_payment_method_url(payment_method_token), headers(env))
    |> response
  end

  def show_transaction(env, transaction_token) do
    HTTPoison.get(show_transaction_url(transaction_token), headers(env))
    |> response
  end

  def show_transcript(env, transaction_token) do
    HTTPoison.get(show_transcript_url(transaction_token), headers(env))
    |> transcript_response
  end

  def list_payment_method_transactions(env, payment_method_token, options \\ []) do
    HTTPoison.get(list_payment_method_transactions_url(payment_method_token, options), headers(env))
    |> response
  end

  def list_gateway_transactions(env, gateway_token, options \\ []) do
    HTTPoison.get(list_gateway_transactions_url(gateway_token, options), headers(env))
    |> response
  end

  defp response({:error, %HTTPoison.Error{reason: reason}}) do
    { :error, reason }
  end
  defp response({:ok, %HTTPoison.Response{status_code: code, body: body}}) when code in [401, 402, 404] do
    error_response(body)
  end
  defp response({:ok, %HTTPoison.Response{status_code: code, body: body}}) when code in [200, 201, 202] do
    ok_response(body)
  end
  defp response({:ok, %HTTPoison.Response{status_code: code, body: body}}) when code in [422, 403] do
    unprocessable(body)
  end

  def unprocessable(body = ~s[{"errors":] <> _rest), do: error_response(body)
  def unprocessable(body), do: ok_response(body)

  defp error_response(body) do
    { :error, body |> extract_reason }
  end

  defp extract_reason(body) do
    parse(body)[:errors]
    |> Enum.map_join("\n", &(&1.message))
  end

  defp ok_response(body) do
    { :ok, map_from(body) }
  end

  defp map_from(body) do
    parse(body) |> Map.values |> List.first
  end

  defp parse(body) do
    Poison.decode!(body, keys: :atoms)
  end

  defp headers(env) do
    encoded = Base.encode64("#{env.environment_key}:#{env.access_secret}")
    [
      "Authorization": "Basic #{encoded}",
      "Content-Type": "application/json"
    ]
  end

  defp transcript_response({:error, %HTTPoison.Error{reason: reason}}), do: { :error, reason }
  defp transcript_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}), do: { :ok, body }
  defp transcript_response({:ok, %HTTPoison.Response{status_code: _, body: body}}), do: { :error, body }

end
