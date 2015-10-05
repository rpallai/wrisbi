class Admin::ExchangeRateLogsController < ApplicationController
	skip_before_filter :authenticate, only: :pull
	before_filter :needs_root, except: :pull
  before_action :set_exchange_rate_log, only: [:edit, :update, :destroy]

  # GET /exchange_rate_logs
  def index
    @exchange_rate_logs = ExchangeRateLog.all
  end

  # GET /exchange_rate_logs/new
  def new
    @exchange_rate_log = ExchangeRateLog.new
  end

  # GET /exchange_rate_logs/1/edit
  def edit
  end

  # POST /exchange_rate_logs
  def create
    @exchange_rate_log = ExchangeRateLog.new(exchange_rate_log_params)

    if @exchange_rate_log.save
      redirect_to :action => :index, notice: 'Exchange rate log was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /exchange_rate_logs/1
  def update
    if @exchange_rate_log.update(exchange_rate_log_params)
      redirect_to :action => :index, notice: 'Exchange rate log was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /exchange_rate_logs/1
  def destroy
    @exchange_rate_log.destroy
    redirect_to exchange_rate_logs_url, notice: 'Exchange rate log was successfully destroyed.'
  end

	def pull
		imported = ExchangeRateLog.pull_all
		render(:text => "Imported %s rate(s)\n" % imported)
	end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exchange_rate_log
      @exchange_rate_log = ExchangeRateLog.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def exchange_rate_log_params
      params[:exchange_rate_log].permit(:date, :currency, :rate)
    end
end
