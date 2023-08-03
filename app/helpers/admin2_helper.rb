module Admin2Helper

  def expand_ul(group_name)
    'show' if expand_rules[group_name.to_sym]&.include?(controller_name)
  end

  def active_li(menu_name)
    'active' if menu_name == controller_name
  end

  def expand_rules
    {
      general: %w[essentials privacy static_content admin_notifications domains],
      design: %w[logos_color landing_page display cover_photos topbar footer landing_page_versions],
      users: %w[manage_users signup_login user_rights invitations user_fields],
      listings: %w[listing_approval listing_comments manage_listings order_types categories listing_fields],
      transactions_reviews: %w[config_transactions manage_transactions conversations manage_reviews],
      payment_system: %w[country_currencies transaction_size stripe paypal],
      emails: %w[newsletters email_users welcome_emails outgoing_emails],
      search_location: %w[search locations],
      social_media: %w[image_tags twitter social_share_buttons],
      seo: %w[sitemap landing_pages search_pages listing_pages category_pages profile_pages google_console],
      analytics: %w[google sharetribe google_manager],
      advanced: %w[custom_scripts delete_marketplaces experimental recaptcha]
    }
  end

  def admin2_landing_page_path
    @current_plan.try(:[], :features).try(:[], :landing_page) ? admin_landing_page_versions_path : admin2_design_landing_page_version_index_path
  end

  def community_name_tag(locale)
    @current_community.full_name(locale).presence
  end

  def social_media_title_placeholder(locale)
    "#{community_name_tag(locale)} - #{community_slogan}"
  end

  def social_media_description_placeholder
    "#{community_description(false)} - #{community_slogan}"
  end

  def admin_title
    title = t('admin2.seo.title', title: content_for(:title), service_name: title_service_name)
    strip_tags(custom_meta_title(title.squish))
  end

  def admin_description
    title = t('admin2.seo.description', title: content_for(:title), service_name: title_service_name)
    strip_tags(custom_meta_description(title.squish))
  end

  def title_service_name
    @current_community.full_name(I18n.locale).to_s
  end

  def community_private_homepage_content
    translations = find_community_customizations(:private_community_homepage_content)
    {
      header: t('admin2.privacy.header'),
      input_classes: 'form-control',
      info_text: t('admin2.privacy.info_text'),
      input_name: 'private_community_homepage_content',
      translations: translations
    }
  end

  def community_posting_rights_content
    translations = find_community_customizations(:verification_to_post_listings_info_content)
    {
      input_classes: 'form-control',
      info_text: t('admin2.user_rights.info_text'),
      input_name: 'verification_to_post_listings_info_content',
      translations: translations
    }
  end

  def community_essentials_hash
    translations = find_community_customizations(:name)
    {
      header: t('admin2.essentials.community_name'),
      input_classes: 'form-control',
      info_text: t('admin2.essentials.community_info_text'),
      input_name: 'name',
      translations: translations
    }
  end

  def community_slogan_hash
    translations = find_community_customizations(:slogan)
    {
      header: t('admin2.essentials.community_slogan'),
      input_classes: 'form-control',
      info_text: t('admin2.essentials.community_slogan_info_text'),
      input_name: 'slogan',
      translations: translations,
      intercom_target: 'Marketplace slogan'
    }
  end

  def community_description_hash
    translations = find_community_customizations(:description)
    {
      header: t('admin2.essentials.community_description'),
      input_classes: 'form-control',
      info_text: t('admin2.essentials.community_description_info_text'),
      input_name: 'description',
      translations: translations,
      intercom_target: 'Marketplace description'
    }
  end

  def bootstrap_class_for(flash_type)
    { success: 'alert-success',
      error: 'alert-danger',
      alert: 'alert-warning',
      notice: 'alert-info' }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      # The flash is used to pass data (e.g. analytics events) in addition to UI
      # messages. Only render flash contents that are meant to be UI messages
      next unless [:success, :error, :alert, :notice].include?(msg_type.to_sym)
      next unless message.present?

      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)}", role: "alert") do
        concat content_tag(:button, 'x', class: "close", data: { dismiss: 'alert' })
        concat message
      end)
    end
    nil
  end

  def period_emails_send
    [[t("admin2.automatic_newsletter.newsletter_daily"), 1],
     [t("admin2.automatic_newsletter.newsletter_weekly"), 7]]
  end

  def find_community_customizations(customization_key)
    available_locales.each_with_object({}) do |(locale_name, locale_value), translations|
      translation = @community_customizations[locale_value][customization_key] || ""
      translations[locale_value] = { language: locale_name, translation: translation }
    end
  end

  def person_name(person)
    if person.present? && !person.deleted?
      display_name = person.display_name.present? ? " (#{person.display_name})" : ''
      "#{person.given_name} #{person.family_name}#{display_name}"
    else
      t('common.removed_user')
    end
  end

  def admin_email_options
    options = %i[all_users posting_allowed with_listing with_listing_no_payment with_payment_no_listing no_listing_no_payment]
    options.delete(:posting_allowed) unless @current_community.require_verification_to_post_listings
    options.map { |option| [I18n.t("admin2.email_users.recipients.options.#{option}"), option] }
  end

  def email_languages
    [[t('admin2.email_users.any_language'), 'any']] | available_locales
  end

  def confirm_opts_order_type(shape)
    count = @current_community.listings.currently_open.where(listing_shape_id: shape.id).count
    if count.positive?
      { url: admin2_listings_order_type_path(shape),
        intercom_target: 'Delete order type',
        caption: t('admin2.order_types.delete_caption', order_type: t(shape.name_tr_key)),
        notice: t('admin2.order_types.confirm_delete_order_type', count: count) }
    else
      { url: admin2_listings_order_type_path(shape),
        intercom_target: 'Delete order type',
        caption: t('admin2.order_types.delete_caption', order_type: t(shape.name_tr_key)),
        notice: t('admin2.order_types.confirm_delete_simple_order_type') }
    end
  end

  def transaction_status_class(status)
    case status
    when 'paid', 'confirmed', 'free', 'refunded'
      'positive'
    when 'payment_intent_action_expired', 'dismissed', 'rejected'
      'neutral'
    when 'canceled', 'disputed'
      'negative'
    when 'pending', 'preauthorized'
      'attention'
    end
  end

  def transaction_badge_class(status)
    case status
    when 'pending_ext', 'preauthorized', 'pending', 'initiated', 'payment_intent_requires_action'
      'badge-pending'
    when 'paid', 'confirmed', 'free', 'refunded', 'accepted'
      'badge-positive'
    when 'dismissed', 'rejected'
      'badge-skipped'
    when 'canceled', 'disputed', 'payment_intent_action_expired', 'payment_intent_failed'
      'badge-negative'
    end
  end

  def date_format(date)
    base = "#{I18n.l(date, format: :short)} (UTC)"
    base.slice!(DateTime.current.year.to_s) if DateTime.current.year == date.year
    base
  end

  def layout_class
    controller_name == 'dashboard' ? 'dashboard-content-wrapper' : 'content-card'
  end

  def logo_image
    @current_community.favicon.path.present? ? @current_community.favicon.url : 'logo-symbol-only.svg'
  end
end
