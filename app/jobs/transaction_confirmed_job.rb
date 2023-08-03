class TransactionConfirmedJob < Struct.new(:conversation_id, :community_id)

  include DelayedAirbrakeNotification

  # This before hook should be included in all Jobs to make sure that the service_name is
  # correct as it's stored in the thread and the same thread handles many different communities
  # if the job doesn't have host parameter, should call the method with nil, to set the default service_name
  def before(job)
    # Set the correct service name to thread for I18n to pick it
    ApplicationHelper.store_community_service_name_to_thread_from_community_id(community_id)
  end

  def perform
    transaction = Transaction.find(conversation_id)
    community = Community.find(community_id)

    # do not send emails on cancellation dismissed
    unless transaction.current_state == 'dismissed'
      MailCarrier.deliver_now(PersonMailer.transaction_confirmed(transaction, community, :seller))
      if transaction.last_transition_by_admin?
        MailCarrier.deliver_now(PersonMailer.transaction_confirmed(transaction, community, :buyer))
      end
    end

    if transaction.payment_gateway == :stripe
      payment = StripeService::Store::StripePayment.get(community_id, transaction.id)
      default_available = APP_CONFIG.stripe_payout_delay.to_f.days.from_now
      available_date = (payment[:available_on] || default_available) + 24.hours
      case StripeService::API::Api.wrapper.charges_mode(community_id)
      when :destination then Delayed::Job.enqueue(StripePayoutJob.new(transaction.id, community_id), :priority => 9, :run_at => available_date)
      when :separate then Delayed::Job.enqueue(StripePayoutJob.new(transaction.id, community_id), :priority => 9)
      end
    end
  end
end
