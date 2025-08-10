# Controller for managing ride requests
class RideRequestsController < ApplicationController
  def create
    rider_id = params[:rider_id]

    result = dispatch_service.request_ride(rider_id)

    if result[:success]
      message = "Ride requested successfully."
      message += " Driver assigned!" if result[:driver_assigned]
      message += " #{result[:assignment_message]}" if result[:assignment_message]
      redirect_to root_path, notice: message
    else
      redirect_to root_path, alert: "Error requesting ride: #{result[:error]}"
    end
  end

  private

  def dispatch_service
    @dispatch_service ||= RideDispatchService.instance
  end
end
