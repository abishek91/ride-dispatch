# Repository for managing drivers in memory
class DriverRepository < BaseRepository
  def find_available_drivers
    where(&:available?)
  end

  def find_drivers_by_status(status)
    where { |driver| driver.status == status }
  end

  def find_drivers_within_radius(x, y, max_distance)
    where { |driver| driver.distance_to(x, y) <= max_distance }
  end

  def find_available_drivers_within_radius(x, y, max_distance)
    find_available_drivers.select { |driver| driver.distance_to(x, y) <= max_distance }
  end

  def find_driver_by_ride_request(ride_request_id)
    find_by { |driver| driver.current_ride_request_id == ride_request_id }
  end

  # Find best drivers for dispatch based on ETA and fairness
  def find_best_drivers_for_pickup(pickup_x, pickup_y, excluded_driver_ids = [])
    available_drivers = find_available_drivers
                       .reject { |driver| excluded_driver_ids.include?(driver.id) }

    # Score drivers based on distance (ETA) and fairness
    scored_drivers = available_drivers.map do |driver|
      eta = driver.distance_to(pickup_x, pickup_y)
      fairness_score = driver.fairness_score

      # Combined score: lower ETA is better, higher fairness is better
      # Normalize both scores and weight them
      eta_score = [ 100 - eta, 0 ].max # Closer drivers get higher scores
      combined_score = (eta_score * 0.6) + (fairness_score * 0.4)

      {
        driver: driver,
        eta: eta,
        fairness_score: fairness_score,
        combined_score: combined_score
      }
    end

    # Sort by combined score (descending - higher is better)
    scored_drivers.sort_by { |scored| -scored[:combined_score] }
  end

  def statistics
    all_drivers = all
    {
      total: all_drivers.count,
      available: find_drivers_by_status(Driver::AVAILABLE).count,
      on_trip: find_drivers_by_status(Driver::ON_TRIP).count,
      offline: find_drivers_by_status(Driver::OFFLINE).count,
      total_rides_completed: all_drivers.sum(&:total_rides_completed)
    }
  end
end
