# Controller for managing riders
class RidersController < ApplicationController
  def create
    pickup_x = params[:pickup_x].to_i
    pickup_y = params[:pickup_y].to_i
    dropoff_x = params[:dropoff_x].to_i
    dropoff_y = params[:dropoff_y].to_i

    if valid_coordinates?(pickup_x, pickup_y) && valid_coordinates?(dropoff_x, dropoff_y)
      result = dispatch_service.add_rider(pickup_x, pickup_y, dropoff_x, dropoff_y)

      if result[:success]
        redirect_to root_path, notice: "Rider added with pickup at (#{pickup_x}, #{pickup_y}) and dropoff at (#{dropoff_x}, #{dropoff_y})"
      else
        redirect_to root_path, alert: "Error adding rider: #{result[:errors].join(', ')}"
      end
    else
      redirect_to root_path, alert: "Invalid coordinates. Must be between 0 and #{RideDispatchService::GRID_SIZE - 1}"
    end
  end

  def destroy
    dispatch_service.remove_rider(params[:id])
    redirect_to root_path, notice: "Rider removed"
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
