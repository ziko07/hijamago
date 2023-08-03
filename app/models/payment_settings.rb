# == Schema Information
#
# Table name: payment_settings
#
#  id                                     :integer          not null, primary key
#  active                                 :boolean          not null
#  community_id                           :integer          not null
#  payment_gateway                        :string(64)
#  payment_process                        :string(64)
#  commission_from_seller                 :integer
#  minimum_price_cents                    :integer
#  minimum_price_currency                 :string(3)
#  minimum_transaction_fee_cents          :integer
#  minimum_transaction_fee_currency       :string(3)
#  confirmation_after_days                :integer          not null
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  api_client_id                          :string(255)
#  api_private_key                        :string(255)
#  api_publishable_key                    :string(255)
#  api_verified                           :boolean
#  api_visible_private_key                :string(255)
#  api_country                            :string(255)
#  commission_from_buyer                  :integer
#  minimum_buyer_transaction_fee_cents    :integer
#  minimum_buyer_transaction_fee_currency :string(3)
#  key_encryption_padding                 :boolean          default(FALSE)
#
# Indexes
#
#  index_payment_settings_on_community_id  (community_id)
#

class PaymentSettings < ApplicationRecord
  belongs_to :community

  validates_presence_of(:community_id)

  scope :preauthorize, -> { where(payment_process: :preauthorize) }
  scope :paypal, -> { preauthorize.where(payment_gateway: :paypal) }
  scope :stripe, -> { preauthorize.where(payment_gateway: :stripe) }
  scope :active, -> { where(active: true) }

  class << self
    def max_minimum_transaction_fee(community)
      stripe.or(PaymentSettings.paypal)
        .active
        .where(community: community)
        .pluck(:minimum_transaction_fee_cents)
        .compact
        .max
    end

    def stripe_sum_transaction_fee(community)
      stripe
      .active
      .where(community: community)
      .sum('IFNULL(minimum_transaction_fee_cents, 0) + IFNULL(minimum_buyer_transaction_fee_cents, 0)')
    end
  end
end
