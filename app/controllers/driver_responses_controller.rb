# Controller for handling driver responses to ride assignments
class DriverResponsesController < ApplicationController
  def accept
    ride_request_id = params[:ride_request_id]

    result = dispatch_service.driver_accept_ride(ride_request_id)

    if result[:success]
      redirect_to root_path, notice: result[:message]
    else
      redirect_to root_path, alert: "Error: #{result[:message]}"
    end
  end

  def reject
    ride_request_id = params[:ride_request_id]

    result = dispatch_service.driver_reject_ride(ride_request_id)

    if result[:success]
      redirect_to root_path, notice: result[:message]
    else
      redirect_to root_path, alert: "Error: #{result[:message]}"
    end
  end

  private

  def dispatch_service
    @dispatch_service ||= RideDispatchService.instance
  end
end
