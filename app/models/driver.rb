# Represents a driver in the ride-hailing system
class Driver
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Driver statuses
  AVAILABLE = "available".freeze
  ON_TRIP = "on_trip".freeze
  OFFLINE = "offline".freeze

  STATUSES = [ AVAILABLE, ON_TRIP, OFFLINE ].freeze

  # Attributes
  attribute :id, :string
  attribute :x, :integer
  attribute :y, :integer
  attribute :status, :string, default: AVAILABLE
  attribute :target_x, :integer # Where the driver is heading
  attribute :target_y, :integer
  attribute :current_ride_request_id, :string
  attribute :total_rides_completed, :integer, default: 0
  attribute :last_ride_completed_at, :datetime

  # Validations
  validates :id, presence: true
  validates :x, :y, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  def initialize(attributes = {})
    super
    self.id ||= SecureRandom.uuid
    self.status ||= AVAILABLE
    self.total_rides_completed ||= 0
  end

  # Status checks
  def available?
    status == AVAILABLE
  end

  def on_trip?
    status == ON_TRIP
  end

  def offline?
    status == OFFLINE
  end

  # Location methods
  def location
    [ x, y ]
  end

  def at_location?(target_x, target_y)
    x == target_x && y == target_y
  end

  def distance_to(target_x, target_y)
    # Manhattan distance for grid-based movement
    (x - target_x).abs + (y - target_y).abs
  end

  # Movement methods
  def move_towards(target_x, target_y)
    return if at_location?(target_x, target_y)

    # Move one step closer (Manhattan distance)
    if x < target_x
      self.x += 1
    elsif x > target_x
      self.x -= 1
    elsif y < target_y
      self.y += 1
    elsif y > target_y
      self.y -= 1
    end
  end

  def set_target(target_x, target_y)
    self.target_x = target_x
    self.target_y = target_y
  end

  # Trip management
  def start_trip(ride_request_id)
    self.status = ON_TRIP
    self.current_ride_request_id = ride_request_id
  end

  def complete_trip
    self.status = AVAILABLE
    self.current_ride_request_id = nil
    self.target_x = nil
    self.target_y = nil
    self.total_rides_completed += 1
    self.last_ride_completed_at = Time.current
  end

  def go_offline
    self.status = OFFLINE
  end

  def go_online
    self.status = AVAILABLE
  end

  # Fairness scoring - drivers who haven't completed rides recently get priority
  def fairness_score
    return 0 if offline?

    base_score = 100

    # Reduce score based on total rides completed (more rides = lower priority)
    ride_penalty = total_rides_completed * 10

    # Increase score if driver hasn't completed a ride recently
    if last_ride_completed_at.nil?
      recency_bonus = 50 # New drivers get bonus
    else
      hours_since_last_ride = (Time.current - last_ride_completed_at) / 1.hour
      recency_bonus = [ hours_since_last_ride * 5, 50 ].min # Max 50 point bonus
    end

    [ base_score - ride_penalty + recency_bonus, 0 ].max
  end

  def to_h
    {
      id: id,
      x: x,
      y: y,
      status: status,
      target_x: target_x,
      target_y: target_y,
      current_ride_request_id: current_ride_request_id,
      total_rides_completed: total_rides_completed,
      last_ride_completed_at: last_ride_completed_at,
      fairness_score: fairness_score
    }
  end
end
