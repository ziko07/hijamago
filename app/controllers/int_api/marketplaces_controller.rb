class IntApi::MarketplacesController < ApplicationController

  skip_before_action :fetch_community, :check_http_auth, :perform_redirect

  before_action :set_access_control_headers

  NewMarketplaceForm = Form::NewMarketplace

  # Creates a marketplace and an admin user for that marketplace
  def create
    return render status: :bad_request, json: {recaptcha_error: "validation failed"} unless validate_recaptcha(params[:recaptcha_token])

    form = NewMarketplaceForm.new(params)
    return render status: :bad_request, json: form.errors unless form.valid?

    # As there's no community yet, we store the global service name to thread
    # so that mail confirmation email is sent from global service name instead
    # of the just created marketplace's name
    ApplicationHelper.store_community_service_name_to_thread(APP_CONFIG.global_service_name)

    marketplace = MarketplaceService.create(
      params.slice(:marketplace_name,
                   :marketplace_type,
                   :marketplace_country,
                   :marketplace_language)
            .merge(payment_process: :preauthorize)
    )

    # Create initial trial plan
    plan = {
      expires_at: Time.now.change({ hour: 9, min: 0, sec: 0 }) + 31.days
    }
    PlanService::API::Api.plans.create_initial_trial(community_id: marketplace.id, plan: plan)

    if marketplace
      TransactionService::API::Api.settings.provision(
        community_id: marketplace.id,
        payment_gateway: :paypal,
        payment_process: :preauthorize,
        active: true)
      TransactionService::API::Api.settings.provision(
        community_id: marketplace.id,
        payment_gateway: :stripe,
        payment_process: :preauthorize,
        active: true)
    end

    user = UserService::API::Users.create_user({
        given_name: params[:admin_first_name],
        family_name: params[:admin_last_name],
        email: params[:admin_email],
        password: params[:admin_password],
        locale: params[:marketplace_language]},
        marketplace.id).data

    base_url = URI(marketplace.full_url)
    url = admin2_url(host: base_url.host, port: base_url.port)

    # make the marketplace creator be logged in via Auth Token
    auth_token = UserService::API::AuthTokens.create_login_token(user[:id])
    url = URLUtils.append_query_param(url, "auth", auth_token[:token])

    # Enable specific features for all new trials
    FeatureFlagService::API::Api.features.enable(community_id: marketplace.id, person_id: user[:id], features: [:topbar_v1])
    FeatureFlagService::API::Api.features.enable(community_id: marketplace.id, features: [:topbar_v1])
    FeatureFlagService::API::Api.features.enable(community_id: marketplace.id, features: [:stripe_connect_onboarding])

    # TODO handle error cases with proper response

    render status: :created, json: {"marketplace_url" => url, "marketplace_id" => marketplace.id}
  end

  private

  def validate_recaptcha(token)
    mode = APP_CONFIG.recaptcha_mode.to_sym
    if APP_CONFIG.recaptcha_secret_key && [:log, :enforce].include?(mode)
      begin
        verify_recaptcha!(
          response: token,
          secret_key: APP_CONFIG.recaptcha_secret_key,
          timeout: 5)
        logger.info('trial_recaptcha_validate_success', nil, {})
      rescue Recaptcha::RecaptchaError => e
        logger.info('trial_recaptcha_validate_error', nil, {error: e.message})
        return mode != :enforce
      end
    end

    return true
  end

  def set_access_control_headers
    # TODO change this to more strict setting when done testing
    headers['Access-Control-Allow-Origin'] = '*'
  end
end
