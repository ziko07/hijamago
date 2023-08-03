# == Schema Information
#
# Table name: conversations
#
#  id              :integer          not null, primary key
#  title           :string(255)
#  listing_id      :integer
#  created_at      :datetime
#  updated_at      :datetime
#  last_message_at :datetime
#  community_id    :integer
#  starting_page   :string(255)
#
# Indexes
#
#  index_conversations_on_community_id     (community_id)
#  index_conversations_on_last_message_at  (last_message_at)
#  index_conversations_on_listing_id       (listing_id)
#  index_conversations_on_starting_page    (starting_page)
#

class Conversation < ApplicationRecord
  STARTING_PAGES = [
    PROFILE = 'profile',
    LISTING = 'listing',
    PAYMENT = 'payment'
  ]

  has_many :messages, :dependent => :destroy

  has_many :participations, :dependent => :destroy
  has_many :participants, :through => :participations, :source => :person
  belongs_to :listing
  has_one :tx, class_name: "Transaction", foreign_key: "conversation_id", dependent: :nullify, inverse_of: :conversation
  belongs_to :community

  validates :starting_page, inclusion: { in: STARTING_PAGES }, allow_nil: true

  scope :for_person, -> (person){
    joins(:participations)
    .where( { participations: { person_id: person.id }} )
  }
  scope :non_payment, -> { where('starting_page IS NULL OR starting_page!=?', [PAYMENT]) }
  scope :payment, -> { where('starting_page IS NULL OR starting_page=?', [PAYMENT]) }
  scope :by_community, -> (community) { where(community: community) }
  scope :non_payment_or_free, -> (community) do
    # Since we do a NOT IN below, include uninitialized transactions in the
    # subquery, so that those conversations are excluded from the final result.
    subquery = Transaction.non_free_including_uninitialized.by_community(community.id).select('conversation_id').to_sql
    by_community(community).where("conversations.id NOT IN (#{subquery})").non_payment
  end
  scope :by_keyword, -> (community, pattern) do
    person_ids_sql = Person.search_name_or_email(community.id, pattern).select('people.id').to_sql
    person_conversations_subquery = joins(:participants).where("people.id IN (#{person_ids_sql})").select('conversations.id').to_sql
    by_community(community)
    .joins(:messages).where("
      (conversations.id IN (#{person_conversations_subquery}))
      OR
      (messages.content LIKE :pattern)
    ", pattern: pattern)
  end

  # Creates a new message to the conversation
  def message_attributes=(attributes)
    if attributes[:content].present? || attributes[:action].present?
      messages.build(attributes)
    end
  end

  # Sets the participants of the conversation
  def conversation_participants=(conversation_participants)
    conversation_participants.each do |participant, is_sender|
      last_at = is_sender.eql?("true") ? "last_sent_at" : "last_received_at"
      participations.build(:person_id => participant,
                           :is_read => is_sender,
                           :is_starter => is_sender,
                           last_at.to_sym => DateTime.now)
    end
  end

  def participation_for(person)
    participations.by_person(person)
  end

  def build_starter_participation(person)
    participations.build(
      person: person,
      is_read: true,
      is_starter: true,
      last_sent_at: DateTime.now
    )
  end

  def build_participation(person)
    participations.build(
      person: person,
      is_read: false,
      is_starter: false,
      last_received_at: DateTime.now
    )
  end

  # Returns last received or sent message
  def last_message
    return messages.last
  end

  def first_message
    return messages.first
  end

  def other_party(person)
    participations.other_party(person).first.try(:person)
  end

  def read_by?(person)
    participation_for(person).is_read
  end

  # Send email notification to message receivers and returns the receivers
  #
  # TODO This should be removed. It's not model's resp to send emails.
  def send_email_to_participants(community)
    recipients(messages.last.sender).each do |recipient|
      if recipient.should_receive?("email_about_new_messages")
        MailCarrier.deliver_now(PersonMailer.new_message_notification(messages.last, community))
      end
    end
  end

  # Returns all the participants except the message sender
  def recipients(sender)
    participants.reject { |p| p.id == sender.id }
  end

  def starter
    participations.starter.first.try(:person)
  end

  def recipient
    participations.recipient.first.try(:person)
  end

  def participant?(user)
    participations.by_person(user).any?
  end

  def with_type(&block)
    block.call(:conversation)
  end

  def with(expected_type, &block)
    with_type do |own_type|
      if own_type == expected_type
        block.call
      end
    end
  end

  def mark_as_read(person_id)
    participations
      .where({ person_id: person_id })
      .update_all({is_read: true})
  end

  def payment?
    starting_page == PAYMENT
  end
end
