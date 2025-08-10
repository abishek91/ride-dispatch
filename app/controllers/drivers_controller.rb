# Controller for managing drivers
class DriversController < ApplicationController
  def create
    x = params[:x].to_i
    y = params[:y].to_i

    if valid_coordinates?(x, y)
      dispatch_service.add_driver(x, y)
      redirect_to root_path, notice: "Driver added at (#{x}, #{y})"
    else
      redirect_to root_path, alert: "Invalid coordinates. Must be between 0 and #{RideDispatchService::GRID_SIZE - 1}"
    end
  end

  def destroy
    if dispatch_service.remove_driver(params[:id])
      redirect_to root_path, notice: "Driver removed"
    else
      redirect_to root_path, alert: "Driver not found"
    end
  end

  def update_status
    driver_id = params[:id]
    status = params[:status]

    if dispatch_service.set_driver_status(driver_id, status)
      redirect_to root_path, notice: "Driver status updated to #{status}"
    else
      redirect_to root_path, alert: "Could not update driver status"
    end
  end

  private

  def dispatch_service
    @dispatch_service ||= RideDispatchService.instance
  end

  def valid_coordinates?(x, y)
    x >= 0 && x < RideDispatchService::GRID_SIZE &&
    y >= 0 && y < RideDispatchService::GRID_SIZE
  end
end
