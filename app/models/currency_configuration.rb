class CurrencyConfiguration < ApplicationRecord
  validates :currency_name, presence: true #validate the presence of the currency_name
end
