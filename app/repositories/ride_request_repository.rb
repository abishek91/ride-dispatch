# Repository for managing ride requests in memory
class RideRequestRepository < BaseRepository
  def find_active_requests
    where(&:active?)
  end

  def find_waiting_requests
    where(&:waiting?)
  end

  def find_completed_requests
    where(&:completed?)
  end

  def find_requests_by_status(status)
    where { |request| request.status == status }
  end

  def find_requests_by_rider(rider_id)
    where { |request| request.rider_id == rider_id }
  end

  def find_requests_by_driver(driver_id)
    where { |request| request.driver_id == driver_id }
  end

  def find_request_by_driver(driver_id)
    find_by { |request| request.driver_id == driver_id && request.active? }
  end

  def find_oldest_waiting_request
    waiting_requests = find_waiting_requests
    return nil if waiting_requests.empty?

    waiting_requests.min_by(&:created_at)
  end

  def statistics
    all_requests = all
    completed_requests = find_completed_requests

    {
      total: all_requests.count,
      waiting: find_waiting_requests.count,
      pending_driver_response: find_requests_by_status(RideRequest::PENDING_DRIVER_RESPONSE).count,
      assigned: find_requests_by_status(RideRequest::ASSIGNED).count,
      driver_en_route: find_requests_by_status(RideRequest::DRIVER_EN_ROUTE).count,
      driver_arrived: find_requests_by_status(RideRequest::DRIVER_ARRIVED).count,
      rider_picked_up: find_requests_by_status(RideRequest::RIDER_PICKED_UP).count,
      completed: completed_requests.count,
      rejected: find_requests_by_status(RideRequest::REJECTED).count,
      failed: find_requests_by_status(RideRequest::FAILED).count,
      total_rejections: all_requests.sum(&:rejection_count)
    }
  end
end
