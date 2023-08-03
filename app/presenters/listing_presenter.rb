require 'fast-polylines'
require 'base64'

class ListingPresenter < MemoisticPresenter
  include ListingAvailabilityManage
  include Rails.application.routes.url_helpers
  attr_accessor :listing, :current_community, :form_path, :params, :current_image, :prev_image_id, :next_image_id
  attr_reader :shape, :current_user

  def initialize(listing, current_community, params, current_user)
    @listing = listing
    @current_community = current_community
    @current_user = current_user
    @params = params
    set_current_image
  end

  def listing_shape=(listing_shape)
    @shape = listing_shape
  end

  def is_author
    @current_user == @listing.author
  end

  def is_marketplace_admin
    Maybe(@current_user).has_admin_rights?(@current_community).or_else(false)
  end

  def is_authorized
    is_authorized = is_author || is_marketplace_admin
  end

  def show_manage_availability
    is_authorized && availability_enabled
  end

  def paypal_in_use
    PaypalHelper.user_and_community_ready_for_payments?(@listing.author_id, @current_community.id)
  end

  def stripe_in_use
    StripeHelper.user_and_community_ready_for_payments?(@listing.author_id, @current_community.id)
  end

  def set_current_image
    @current_image = if params[:image]
      @listing.image_by_id(params[:image])
    else
      @listing.listing_images.first
    end

    @prev_image_id, @next_image_id = if @current_image
      @listing.prev_and_next_image_ids_by_id(@current_image.id)
    else
      [nil, nil]
    end
  end

  def received_testimonials
    @listing.author.received_testimonials.by_community(@current_community)
  end

  def received_positive_testimonials
    @listing.author.received_positive_testimonials.by_community(@current_community)
  end

  def feedback_positive_percentage
    @listing.author.feedback_positive_percentage_in_community(@current_community)
  end

  def youtube_link_ids
    ListingViewUtils.youtube_video_ids(@listing.description)
  end

  def currency
    Maybe(@listing.price).currency.or_else(Money::Currency.new(@current_community.currency))
  end

  def community_country_code
    LocalizationUtils.valid_country_code(@current_community.country)
  end

  def process
    return nil unless @listing.transaction_process_id

    get_transaction_process(community_id: @current_community.id, transaction_process_id: @listing.transaction_process_id)
  end

  def delivery_opts
    delivery_config(@listing.require_shipping_address, @listing.pickup_enabled, @listing.shipping_price, @listing.shipping_price_additional, @listing.currency)
  end

  def listing_unit_type
    @listing.unit_type
  end

  def currency_opts
    MoneyViewUtils.currency_opts(I18n.locale, currency)
  end

  def delivery_config(require_shipping_address, pickup_enabled, shipping_price, shipping_price_additional, currency)
    shipping = delivery_price_hash(:shipping, shipping_price, shipping_price_additional) if require_shipping_address
    pickup = delivery_price_hash(:pickup, Money.new(0, currency), Money.new(0, currency))

    case [require_shipping_address, pickup_enabled]
    when matches([true, true])
      [shipping, pickup]
    when matches([true, false])
      [shipping]
    when matches([false, true])
      [pickup]
    else
      []
    end
  end

  def get_transaction_process(community_id:, transaction_process_id:)
    opts = {
      process_id: transaction_process_id,
      community_id: community_id
    }

    TransactionService::API::Api.processes.get(community_id: community_id, process_id: transaction_process_id)
      .maybe
      .process
      .or_else(nil)
      .tap { |process|
        raise ArgumentError.new("Cannot find transaction process: #{opts}") if process.nil?
      }
  end

  def delivery_type
    delivery_opts.present? ? delivery_opts.first[:name].to_s : ""
  end

  def shipping_price_additional
    delivery_opts.present? ? delivery_opts.first[:shipping_price_additional] : nil
  end

  def delivery_price_hash(delivery_type, price, shipping_price_additional)
    { name: delivery_type,
      price: price,
      shipping_price_additional: shipping_price_additional,
      price_info: ListingViewUtils.shipping_info(delivery_type, price, shipping_price_additional)
    }
  end

  def category_tree
    CategoryViewUtils.category_tree(
      categories: @current_community.categories,
      shapes: @current_community.shapes,
      locale: I18n.locale,
      all_locales: @current_community.locales
    )
  end

  def shapes
    ListingShape.where(community_id: @current_community.id).exist_ordered.all
  end

  def categories
    @current_community.top_level_categories
  end

  def subcategories
    @current_community.subcategories
  end

  def commission
    paypal_ready = PaypalHelper.community_ready_for_payments?(@current_community.id)
    stripe_ready = StripeHelper.community_ready_for_payments?(@current_community.id)

    supported = []
    supported << :paypal if paypal_ready
    supported << :stripe if stripe_ready
    payment_type = supported.size > 1 ? supported : supported.first

    currency = @current_community.currency
    process_id = shape ? shape[:transaction_process_id] : @listing.transaction_process_id
    process = get_transaction_process(community_id: @current_community.id, transaction_process_id: process_id)

    case [payment_type, process]
    when matches([nil, :preauthorize])
      {
        not_found_gateways: true
      }
    when matches([__, :none])
      {
        commission_from_seller: 0,
        minimum_commission: Money.new(0, currency),
        minimum_price_cents: 0,
        payment_gateway: nil,
        paypal_commission: 0,
        paypal_minimum_transaction_fee: 0,
        seller_commission_in_use: false,
        stripe_commission: 0,
        stripe_minimum_transaction_fee: 0
      }
    when matches([:paypal]), matches([:stripe]), matches([[:paypal, :stripe]])
      p_set = Maybe(payment_settings_api.get_active_by_gateway(community_id: @current_community.id, payment_gateway: payment_type))
        .select {|res| res[:success]}
        .map {|res| res[:data]}
        .or_else({})

      paypal_settings = Maybe(payment_settings_api.get_active_by_gateway(community_id: @current_community.id, payment_gateway: :paypal))
        .select {|res| res[:success]}
        .map {|res| res[:data]}
        .or_else({})

      {
        commission_from_seller: p_set[:commission_from_seller],
        minimum_commission: Money.new(p_set[:minimum_transaction_fee_cents], currency),
        minimum_price_cents: @current_community.minimum_price_cents,
        payment_gateway: payment_type,
        paypal_commission: paypal_settings[:commission_from_seller],
        paypal_minimum_transaction_fee: Money.new(paypal_settings[:minimum_transaction_fee_cents], currency),
        seller_commission_in_use: p_set[:commission_type] != :none,
        stripe_commission: stripe_settings[:commission_from_seller],
        stripe_minimum_transaction_fee: Money.new(stripe_settings[:minimum_transaction_fee_cents], currency)
      }
    else
      raise ArgumentError.new("Unknown payment_type, process combination: [#{payment_type}, #{process}]")
    end
  end

  def stripe_settings
    Maybe(payment_settings_api.get_active_by_gateway(community_id: @current_community.id, payment_gateway: :stripe))
      .select {|res| res[:success]}
      .map {|res| res[:data]}
      .or_else({})
  end

  def payment_settings_api
    TransactionService::API::Api.settings
  end

  def unit_options
    unit_options = ListingViewUtils.unit_options(shape.units, unit_from_listing(@listing))
  end

  def unit_from_listing(listing)
    HashUtils.compact({
      unit_type: listing.unit_type.present? ? listing.unit_type.to_s : nil,
      quantity_selector: listing.quantity_selector,
      unit_tr_key: listing.unit_tr_key,
      unit_selector_tr_key: listing.unit_selector_tr_key
    })
  end

  def paypal_fees_url
    PaypalCountryHelper.fee_link(community_country_code)
  end

  def stripe_fees_url
    "https://stripe.com/#{community_country_code.downcase}/pricing"
  end

  def shipping_price
    @listing.shipping_price || "0"
  end

  def shipping_enabled
    @listing.require_shipping_address?
  end

  def pickup_enabled
    @listing.pickup_enabled?
  end

  def shipping_price_additional_in_form
    if @listing.shipping_price_additional
      @listing.shipping_price_additional.to_s
    elsif @listing.shipping_price
      @listing.shipping_price.to_s
    else
      0
    end
  end

  def always_show_additional_shipping_price
    shape && shape.units.length == 1 && shape.units.first[:kind] == 'quantity'
  end

  def category_id
    @listing.category.parent_id || @listing.category.id
  end

  def subcategory_id
    @listing.category.parent_id ?  @listing.category.id : nil
  end

  def payments_enabled?
    process == :preauthorize
  end

  def acts_as_person
    if params[:person_id].present? &&
       current_user.has_admin_rights?(current_community)
      current_community.members.find_by!(username: params[:person_id])
    end
  end

  def new_listing_author
    acts_as_person || @current_user
  end

  def listing_form_menu_titles
    {
      "category" => I18n.t("listings.new.select_category"),
      "subcategory" => I18n.t("listings.new.select_subcategory"),
      "listing_shape" => I18n.t("listings.new.select_transaction_type")
    }
  end

  def new_listing_form
    {
      locale: I18n.locale,
      category_tree: category_tree,
      menu_titles: listing_form_menu_titles,
      new_form_content_path: acts_as_person ? new_form_content_person_listings_path(person_id: new_listing_author.username, locale: I18n.locale) : new_form_content_listings_path(locale: I18n.locale)
    }
  end

  def buyer_fee?
    stripe_in_use && !paypal_in_use &&
      (stripe_settings[:commission_from_buyer].to_i > 0 ||
      stripe_settings[:minimum_buyer_transaction_fee_cents].to_i > 0)
  end

  def pending_admin_approval?
    is_marketplace_admin && listing.approval_pending?
  end

  def approval_in_use?
    current_community.pre_approved_listings
  end

  def show_submit_for_review?
    approval_in_use? && !current_user.has_admin_rights?(current_community)
  end

  def listing_form_object
    if acts_as_person
      [acts_as_person, listing]
    else
      listing
    end
  end

  def static_google_maps_url
    lat, lon = MapService.obfuscated_coordinates(@listing.id,
                                                 @listing.location&.latitude,
                                                 @listing.location&.longitude)

    key = MarketplaceHelper.google_maps_key(@current_community.id)

    params = StaticGoogleMapParams.new(
      lat: lat,
      lng: lon,
      key: key)

    if APP_CONFIG.google_maps_signing_secret && key == APP_CONFIG.google_maps_key
      params.signed_url(APP_CONFIG.google_maps_signing_secret)
    else
      params.url
    end
  end

  class StaticGoogleMapParams
    attr_reader :lat, :lng, :key, :color, :fillcolor, :weight, :radius

    STATIC_MAPS_BASE_URL = "https://maps.googleapis.com"
    STATIC_MAPS_BASE_PATH = "/maps/api/staticmap"

    def initialize(lat:, lng:, key:)
      @lat = lat
      @lng = lng
      @key = key
      @color = '0xC0392B4C'
      @fillcolor = '0xC0392B33'
      @weight = '1'
      @radius = 500
    end

    def params
      {
        center: "#{lat},#{lng}",
        key: key,
        maptype: 'roadmap',
        path: path,
        size: '500x358',
        zoom: 13
      }
    end

    def url
      "#{STATIC_MAPS_BASE_URL}#{STATIC_MAPS_BASE_PATH}?#{params.to_query}"
    end

    def signed_url(signing_secret)
      url = "#{STATIC_MAPS_BASE_PATH}?#{params.to_query}"
      secret_bytes = Base64.urlsafe_decode64(signing_secret)

      digest = OpenSSL::Digest.new('sha1')
      signature = Base64.urlsafe_encode64(OpenSSL::HMAC.digest(digest, secret_bytes, url))

      "#{STATIC_MAPS_BASE_URL}#{url}&signature=#{signature}"
    end

    private

    def path
      {
        color: color,
        fillcolor: fillcolor,
        weight: weight,
        enc: FastPolylines.encode(circle_polyline(lat, lng, radius))
      }.map{|k,v| "#{k}:#{v}"}.join('|')
    end

    def circle_polyline(lat, lng, radius)
      detail = 8
      r = 6371

      lat_r = (lat.to_f * Math::PI) / 180
      lng_r = (lng.to_f * Math::PI) / 180
      d = radius.to_f / 1000 / r

      points = []
      (0..360).step(detail) do |i|
        brng = (i * Math::PI) / 180

        point_lat = Math.asin(
          Math.sin(lat_r) * Math.cos(d) + Math.cos(lat_r) * Math.sin(d) * Math.cos(brng)
        )
        point_lng =
          ((lng_r +
            Math.atan2(
              Math.sin(brng) * Math.sin(d) * Math.cos(lat_r),
              Math.cos(d) - Math.sin(lat_r) * Math.sin(point_lat)
            )) *
            180) /
          Math::PI
        point_lat = (point_lat * 180) / Math::PI

        point_lat = normalize(point_lat)
        point_lng = normalize(point_lng)

        points.push([point_lat, point_lng])
      end

      points
    end

    def normalize(coord)
      if coord < -180
        coord += 360
      elsif coord > 180
        coord -= 360
      end
      coord
    end
  end

  memoize_all_reader_methods
end
