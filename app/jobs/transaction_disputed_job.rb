class TransactionDisputedJob < Struct.new(:transaction_id, :community_id)

  include DelayedAirbrakeNotification

  def before(job)
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(community_id)
  end

  def perform
    transaction = Transaction.find(transaction_id)
    community = Community.find(community_id)
    TransactionMailer.transaction_disputed(transaction,
                                           transaction.seller,
                                           false,
                                           true).deliver_now
    TransactionMailer.transaction_disputed(transaction,
                                           transaction.buyer,
                                           false,
                                           false).deliver_now
    community.admins.each do |admin|
      TransactionMailer.transaction_disputed(transaction,
                                             admin,
                                             true,
                                             false).deliver_now
    end
  end
end
