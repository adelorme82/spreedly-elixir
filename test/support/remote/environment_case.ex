defmodule Remote.Environment.Case do
  defmacro __using__(_opts) do
    quote do
      @moduletag [:remote]
      use ExUnit.Case, async: true

      alias Spreedly.Environment

      defp card_deets(options \\ []) do
        default_deets = [
          email: "matrim@wot.com", number: "5555555555554444", month: 1, year: 2019,
          last_name: "Cauthon", first_name: "Matrim"
        ]
        Keyword.merge(default_deets, options)
      end

      defp env do
        Environment.new(Application.get_env(:spreedly, :environment_key), Application.get_env(:spreedly, :access_secret))
      end

      defp create_test_gateway do
        { :ok, gateway } = Environment.add_gateway(env(), :test)
        gateway
      end

      defp create_test_receiver do
        { :ok, gateway } = Environment.add_receiver(env(), :test, hostnames: "http://posttestserver.com")
        gateway
      end

      defp create_test_card do
        { :ok, transaction } = Environment.add_credit_card(env(), card_deets())
        transaction.payment_method
      end

      defp create_declined_test_card do
        { :ok, transaction } = Environment.add_credit_card(env(), card_deets(number: "4012888888881881"))
        transaction.payment_method
      end

      defp create_verify_transaction do
        {:ok, trans } = Environment.verify(env(), create_test_gateway().token, create_test_card().token)
        trans
      end

      defp create_purchase_transaction do
        {:ok, trans } = Environment.purchase(env(), create_test_gateway().token, create_test_card().token, 100)
        trans
      end

      defp create_auth_transaction do
        {:ok, trans } = Environment.authorization(env(), create_test_gateway().token, create_test_card().token, 100)
        trans
      end

    end
  end

end
