module Admin2::General
  class EssentialsController < Admin2::AdminBaseController

    def index
      @community_customizations = find_or_initialize_customizations(@current_community.locales)
      all_locales = MarketplaceService.all_locales.map { |l|
        { locale_key: l[:locale_key],
          translated_name: t("admin.communities.available_languages.#{l[:locale_key]}") }
      }.sort_by { |l| l[:translated_name] }
      enabled_locale_keys = available_locales.map(&:second)
      @clp_enabled = clp_enabled
      render locals: { locale_selection_locals:
                         { all_locales: all_locales,
                           enabled_locale_keys: enabled_locale_keys,
                           unofficial_locales: unofficial_locales } }
    end

    def update_essential
      update_results = []
      slogan_and_description_before = slogan_and_description_present?(@current_community.community_customizations)
      analytic = AnalyticService::CommunityCustomizations.new(user: @current_user, community: @current_community)
      @current_community.locales.map do |locale|
        customizations = find_or_initialize_customizations_for_locale(locale)
        customizations.assign_attributes(community_custom_params(locale))
        analytic.process(customizations)
        update_results.push(customizations.update({}))
      end
      update_results.push(@current_community.update(community_params))
      process_locales = unofficial_locales.blank?
      if process_locales
        enabled_locales = params[:enabled_locales]
        all_locales = MarketplaceService.all_locales.map { |l| l[:locale_key] }.to_set
        enabled_locales_valid = enabled_locales.present? && enabled_locales.map{ |locale| all_locales.include?(locale) }.all?
        if enabled_locales_valid
          MarketplaceService.set_locales(@current_community, enabled_locales)
        end
      end
      analytic.send_properties

      if update_results.all? && (!process_locales || enabled_locales_valid)
        slogan_and_description_after = slogan_and_description_present?(@current_community.community_customizations.reload)
        if !slogan_and_description_before && slogan_and_description_after
          record_event(flash, "km_record", {km_event: "Onboarding slogan/description created"})
        end
        flash[:notice] = t('admin2.notifications.essentials_updated')
      else
        raise t('admin2.notifications.essentials_update_failed')
      end
    rescue StandardError => e
      flash[:error] = e.message
    ensure
      redirect_to admin2_general_essentials_path
    end

    private

    def slogan_and_description_present?(community_customizations)
      slogan_present = community_customizations.all? { |c| c.slogan.present? }
      description_present = community_customizations.all? { |c| c.description.present? }
      slogan_present && description_present
    end

    def community_custom_params(locale)
      params.require(:community_customizations)
            .require(locale).permit(:name,
                                    :slogan,
                                    :description)
    end

    def community_params
      params.require(:community).permit(:description_color,
                                        :slogan_color,
                                        :show_slogan,
                                        :show_description)
    end

    def unofficial_locales
      all_locales = MarketplaceService.all_locales.map { |l| l[:locale_key] }
      @current_community.locales.reject { |locale| all_locales.include?(locale) }
                        .map { |unsupported_locale_key|
                           unsupported_locale_name = Sharetribe::AVAILABLE_LOCALES.select { |l| l[:ident] == unsupported_locale_key }.map { |l| l[:name] }.first
                           { key: unsupported_locale_key, name: unsupported_locale_name }
                        }
    end

    def build_customization_with_defaults(locale)
      @current_community.community_customizations.build(
        slogan: @current_community.slogan,
        description: @current_community.description,
        locale: locale
      )
    end
  end
end
