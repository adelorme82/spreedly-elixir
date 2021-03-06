defmodule Remote.ShowTranscriptTest do
  use Remote.Environment.Case

  test "invalid credentials" do
    bogus_env = Environment.new("invalid", "credentials")
    { :error, reason } = Environment.show_transcript(bogus_env, "SomeToken")
    assert reason =~ "Unable to authenticate"
  end

  test "non existent" do
    { :error, reason } = Environment.show_transcript(env(), "NonExistentToken")
    assert reason =~ "Unable to find the transaction"
  end

  test "success" do
    {:ok, transcript } = Environment.show_transcript(env(), create_verify_transaction().token)
    assert transcript == ""
  end

end
