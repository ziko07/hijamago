class IntApi::ListingsController < ApplicationController
  respond_to :json

  before_action :ensure_current_user_is_listing_author

  def update_working_time_slots
    listing.update_column(:per_hour_ready, true)
    listing.update(working_time_slots_params)
    respond_with listing.working_hours_as_json, location: nil
  end

  def update_blocked_dates
    listing.update(blocked_dates_params)
    head :ok
  end

  private

  def listing
    @listing ||= @current_community.listings.find(params[:id])
  end

  def working_time_slots_params
    params.require(:listing).permit(
      working_time_slots_attributes: [:id, :from, :till, :week_day, :_destroy]
    )
  end

  def blocked_dates_params
    params.require(:listing).permit(
      blocked_dates_attributes: [:id, :blocked_at, :_destroy]
    )
  end

  def ensure_current_user_is_listing_author
    return true if !listing.deleted? && (current_user?(listing.author) || @current_user.has_admin_rights?(@current_community))

    head(:forbidden)
  end
end
