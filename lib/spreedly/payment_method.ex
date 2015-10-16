defmodule Spreedly.PaymentMethod do

  defstruct ~w(
    token payment_method_type email first_name last_name full_name month year number last_four_digits
    first_six_digits card_type verification_value address1 address2 city state zip
    country phone_number company storage_state xml)a

  def new_from_xml(xml) do
    XML.into_struct(xml, __MODULE__)
  end

end