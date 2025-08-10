# Main controller for the ride dispatch simulation
class SimulationController < ApplicationController
  def index
    @system_state = dispatch_service.get_system_state
  end

  def tick
    @tick_results = dispatch_service.tick
    redirect_to root_path, notice: "System advanced by 1 tick. Movements: #{@tick_results[:movements].count}, Status changes: #{@tick_results[:status_changes].count}, Completed rides: #{@tick_results[:completed_rides].count}"
  end

  def reset
    dispatch_service.reset_system
    redirect_to root_path, notice: "System has been reset"
  end

  private

  def dispatch_service
    @dispatch_service ||= RideDispatchService.instance
  end
end
