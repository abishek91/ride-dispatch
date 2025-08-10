# Service for managing the ride dispatch system
class RideDispatchService
  include Singleton

  # Grid configuration
  GRID_SIZE = 100
  MAX_ASSIGNMENT_ATTEMPTS = 5
  DRIVER_REJECTION_PROBABILITY = 0.2 # 20% chance driver rejects

  def initialize
    @driver_repository = DriverRepository.new
    @rider_repository = RiderRepository.new
    @ride_request_repository = RideRequestRepository.new
    @pending_assignments = {} # Track assignments waiting for driver response
  end

  # Driver management
  def add_driver(x, y)
    driver = Driver.new(x: x, y: y)
    @driver_repository.create(driver)
    driver
  end

  def remove_driver(driver_id)
    driver = @driver_repository.find(driver_id)
    return false unless driver

    # If driver is on a trip, mark the ride request as failed
    if driver.on_trip? && driver.current_ride_request_id
      ride_request = @ride_request_repository.find(driver.current_ride_request_id)
      ride_request&.mark_as_failed
      @ride_request_repository.update(ride_request) if ride_request
    end

    @driver_repository.delete(driver_id)
    true
  end

  def set_driver_status(driver_id, status)
    driver = @driver_repository.find(driver_id)
    return false unless driver && Driver::STATUSES.include?(status)

    # If setting driver to offline and they're on a trip, fail the ride
    if status == Driver::OFFLINE && driver.on_trip? && driver.current_ride_request_id
      ride_request = @ride_request_repository.find(driver.current_ride_request_id)
      ride_request&.mark_as_failed
      @ride_request_repository.update(ride_request) if ride_request
    end

    case status
    when Driver::OFFLINE
      driver.go_offline
    when Driver::AVAILABLE
      driver.go_online
    end

    @driver_repository.update(driver)
    true
  end

  # Rider management
  def add_rider(pickup_x, pickup_y, dropoff_x, dropoff_y)
    rider = Rider.new(
      x: pickup_x,           # Set current location to pickup initially
      y: pickup_y,
      pickup_x: pickup_x,
      pickup_y: pickup_y,
      dropoff_x: dropoff_x,
      dropoff_y: dropoff_y
    )

    return { success: false, errors: rider.errors.full_messages } unless rider.valid?

    @rider_repository.create(rider)
    { success: true, rider: rider }
  end

  def remove_rider(rider_id)
    @rider_repository.delete(rider_id)
  end

  # Ride request management
  def request_ride(rider_id)
    rider = @rider_repository.find(rider_id)
    return { success: false, error: "Rider not found" } unless rider

    # Check if rider already has an active request
    existing_request = @ride_request_repository.find_active_requests
                                              .find { |req| req.rider_id == rider_id }

    if existing_request
      return { success: false, error: "Rider already has an active ride request" }
    end

    # Create ride request
    ride_request = RideRequest.new(
      rider_id: rider_id,
      pickup_x: rider.pickup_x,
      pickup_y: rider.pickup_y,
      dropoff_x: rider.dropoff_x,
      dropoff_y: rider.dropoff_y
    )

    @ride_request_repository.create(ride_request)

    # Attempt to assign a driver
    assignment_result = assign_driver_to_request(ride_request)

    {
      success: true,
      ride_request: ride_request,
      driver_assigned: assignment_result[:success],
      assignment_message: assignment_result[:message]
    }
  end

  # Core dispatch logic
  def assign_driver_to_request(ride_request)
    return { success: false, message: "Request not in waiting status" } unless ride_request.waiting?

    # Get excluded driver IDs (those who have already rejected)
    excluded_driver_ids = JSON.parse(ride_request.rejected_driver_ids)

    # Find best drivers using our scoring algorithm
    scored_drivers = @driver_repository.find_best_drivers_for_pickup(
      ride_request.pickup_x,
      ride_request.pickup_y,
      excluded_driver_ids
    )

    return { success: false, message: "No available drivers found" } if scored_drivers.empty?

    # Try to assign to the best driver
    best_scored_driver = scored_drivers.first
    driver = best_scored_driver[:driver]

    # Set ride request as pending driver response
    ride_request.set_pending_driver_response(driver.id)
    @ride_request_repository.update(ride_request)

    # Store pending assignment for UI interaction
    @pending_assignments[ride_request.id] = {
      ride_request: ride_request,
      driver: driver,
      eta: best_scored_driver[:eta]
    }

    {
      success: true,
      message: "Driver #{driver.id[0..7]} offered ride request (ETA: #{best_scored_driver[:eta]} blocks) - Waiting for response",
      driver: driver,
      eta: best_scored_driver[:eta],
      pending_response: true
    }
  end

  # Handle driver response to ride assignment
  def driver_accept_ride(ride_request_id)
    pending = @pending_assignments[ride_request_id]
    return { success: false, message: "No pending assignment found" } unless pending

    ride_request = pending[:ride_request]
    driver = pending[:driver]

    # Driver accepts
    ride_request.assign_driver(driver.id)
    driver.start_trip(ride_request.id)
    driver.set_target(ride_request.pickup_x, ride_request.pickup_y)

    @ride_request_repository.update(ride_request)
    @driver_repository.update(driver)
    @pending_assignments.delete(ride_request_id)

    {
      success: true,
      message: "Driver #{driver.id[0..7]} accepted the ride request and is en route to pickup"
    }
  end

  def driver_reject_ride(ride_request_id)
    pending = @pending_assignments[ride_request_id]
    return { success: false, message: "No pending assignment found" } unless pending

    ride_request = pending[:ride_request]
    driver = pending[:driver]

    # Driver rejects
    ride_request.reject_by_driver(driver.id)
    @ride_request_repository.update(ride_request)
    @pending_assignments.delete(ride_request_id)

    # If too many rejections, mark as failed
    if ride_request.rejection_count >= MAX_ASSIGNMENT_ATTEMPTS
      ride_request.mark_as_failed
      @ride_request_repository.update(ride_request)
      { success: false, message: "Request failed after #{MAX_ASSIGNMENT_ATTEMPTS} rejections" }
    else
      # Try to assign to next best driver
      assignment_result = assign_driver_to_request(ride_request)
      {
        success: true,
        message: "Driver #{driver.id[0..7]} rejected. #{assignment_result[:message]}"
      }
    end
  end

  def get_pending_assignments
    @pending_assignments.values
  end

  # Time advancement - core simulation logic
  def tick
    results = {
      movements: [],
      status_changes: [],
      completed_rides: [],
      new_assignments: []
    }

    # Move all drivers towards their targets
    @driver_repository.all.each do |driver|
      next unless driver.on_trip? && driver.target_x && driver.target_y

      old_location = [ driver.x, driver.y ]
      driver.move_towards(driver.target_x, driver.target_y)

      if old_location != [ driver.x, driver.y ]
        # Check if driver has a picked up rider who should move with them
        ride_request = @ride_request_repository.find(driver.current_ride_request_id)
        if ride_request && ride_request.rider_picked_up?
          # Move rider with driver
          rider = @rider_repository.find(ride_request.rider_id)
          if rider
            rider.x = driver.x
            rider.y = driver.y
            @rider_repository.update(rider)
          end
        end

        results[:movements] << {
          driver_id: driver.id,
          from: old_location,
          to: [ driver.x, driver.y ],
          target: [ driver.target_x, driver.target_y ]
        }
        @driver_repository.update(driver)
      end

      # Check if driver reached their target
      if driver.at_location?(driver.target_x, driver.target_y)
        handle_driver_arrival(driver, results)
      end
    end

    # Try to assign drivers to waiting requests (not pending response)
    @ride_request_repository.find_waiting_requests.each do |ride_request|
      assignment_result = assign_driver_to_request(ride_request)
      if assignment_result[:success] && assignment_result[:pending_response]
        results[:new_assignments] << {
          ride_request_id: ride_request.id,
          driver_id: assignment_result[:driver].id,
          eta: assignment_result[:eta],
          pending_response: true
        }
      end
    end

    results
  end

  # Get system state for UI
  def get_system_state
    {
      drivers: @driver_repository.all.map(&:to_h),
      riders: @rider_repository.all.map(&:to_h),
      ride_requests: @ride_request_repository.all.map(&:to_h),
      pending_assignments: get_pending_assignments,
      statistics: {
        drivers: @driver_repository.statistics,
        riders: @rider_repository.statistics,
        ride_requests: @ride_request_repository.statistics
      }
    }
  end

  # Reset system
  def reset_system
    @driver_repository.clear
    @rider_repository.clear
    @ride_request_repository.clear
    @pending_assignments.clear
  end

  private

  def handle_driver_arrival(driver, results)
    ride_request = @ride_request_repository.find(driver.current_ride_request_id)
    return unless ride_request

    case ride_request.status
    when RideRequest::ASSIGNED
      # Driver reached pickup location
      ride_request.driver_arrive_at_pickup
      ride_request.pick_up_rider
      driver.set_target(ride_request.dropoff_x, ride_request.dropoff_y)

      results[:status_changes] << {
        ride_request_id: ride_request.id,
        status: "rider_picked_up",
        location: [ driver.x, driver.y ]
      }

    when RideRequest::RIDER_PICKED_UP
      # Driver reached dropoff location
      ride_request.complete_ride
      driver.complete_trip

      # Rider is already at the dropoff location (moved with driver during journey)
      results[:completed_rides] << {
        ride_request_id: ride_request.id,
        driver_id: driver.id,
        rider_id: ride_request.rider_id,
        dropoff_location: [ driver.x, driver.y ]
      }
    end

    @ride_request_repository.update(ride_request)
    @driver_repository.update(driver)
  end

  def validate_coordinates(x, y)
    x >= 0 && x < GRID_SIZE && y >= 0 && y < GRID_SIZE
  end
end
