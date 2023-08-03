module Admin2::TransactionsReviews
  class ManageTransactionsController < Admin2::AdminBaseController
    before_action :set_presenter

    def index; end

    def show; end

    def export
      @export_result = ExportTaskResult.create
      Delayed::Job.enqueue(ExportTransactionsJob.new(@current_user.id, @current_community.id, @export_result.id))
      render layout: false
    end

    def confirm
      unless @service.confirm
        flash[:error] = t('layouts.notifications.something_went_wrong')
      end
      redirect_to admin2_transactions_reviews_manage_transaction_path(@service.transaction)
    end

    def cancel
      unless @service.cancel
        flash[:error] = t('layouts.notifications.something_went_wrong')
      end
      redirect_to admin2_transactions_reviews_manage_transaction_path(@service.transaction)
    end

    def refund
      unless @service.refund
        flash[:error] = t('layouts.notifications.something_went_wrong')
      end
      redirect_to admin2_transactions_reviews_manage_transaction_path(@service.transaction)
    end

    def dismiss
      unless @service.dismiss
        flash[:error] = t('layouts.notifications.something_went_wrong')
      end
      redirect_to admin2_transactions_reviews_manage_transaction_path(@service.transaction)
    end

    def export_status
      export_result = ExportTaskResult.find_by(token: params[:token])
      if export_result
        file_url = if export_result.file.present?
                     export_result.file.expiring_url(ExportTaskResult::AWS_S3_URL_EXPIRES_SECONDS)
                   end
        render json: { token: export_result.token, status: export_result.status, url: file_url }
      else
        render json: { status: 'error' }
      end
    end

    private

    def set_presenter
      @service = Admin::TransactionsService.new(@current_community,
                                                params, request.format,
                                                @current_user, false, 100)
      @transactions_presenter = Admin2::TransactionsPresenter.new(params, @service)
    end
  end
end
