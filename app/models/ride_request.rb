# Represents a ride request in the system
class RideRequest
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Request statuses
  WAITING = "waiting".freeze
  PENDING_DRIVER_RESPONSE = "pending_driver_response".freeze
  ASSIGNED = "assigned".freeze
  DRIVER_EN_ROUTE = "driver_en_route".freeze
  DRIVER_ARRIVED = "driver_arrived".freeze
  RIDER_PICKED_UP = "rider_picked_up".freeze
  COMPLETED = "completed".freeze
  REJECTED = "rejected".freeze
  FAILED = "failed".freeze

  STATUSES = [ WAITING, PENDING_DRIVER_RESPONSE, ASSIGNED, DRIVER_EN_ROUTE, DRIVER_ARRIVED, RIDER_PICKED_UP, COMPLETED, REJECTED, FAILED ].freeze

  # Attributes
  attribute :id, :string
  attribute :rider_id, :string
  attribute :pickup_x, :integer
  attribute :pickup_y, :integer
  attribute :dropoff_x, :integer
  attribute :dropoff_y, :integer
  attribute :status, :string, default: WAITING
  attribute :driver_id, :string
  attribute :created_at, :datetime
  attribute :assigned_at, :datetime
  attribute :picked_up_at, :datetime
  attribute :completed_at, :datetime
  attribute :rejection_count, :integer, default: 0
  attribute :rejected_driver_ids, :string, default: "[]" # JSON array as string

  # Validations
  validates :id, presence: true
  validates :rider_id, presence: true
  validates :pickup_x, :pickup_y, :dropoff_x, :dropoff_y,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :rejection_count, numericality: { greater_than_or_equal_to: 0 }

  def initialize(attributes = {})
    super
    self.id ||= SecureRandom.uuid
    self.status ||= WAITING
    self.created_at ||= Time.current
    self.rejection_count ||= 0
    self.rejected_driver_ids ||= "[]"
  end

  # Status checks
  def waiting?
    status == WAITING
  end

  def pending_driver_response?
    status == PENDING_DRIVER_RESPONSE
  end

  def assigned?
    status == ASSIGNED
  end

  def driver_en_route?
    status == DRIVER_EN_ROUTE
  end

  def driver_arrived?
    status == DRIVER_ARRIVED
  end

  def rider_picked_up?
    status == RIDER_PICKED_UP
  end

  def completed?
    status == COMPLETED
  end

  def rejected?
    status == REJECTED
  end

  def failed?
    status == FAILED
  end

  def active?
    ![ COMPLETED, REJECTED, FAILED ].include?(status)
  end

  # Location methods
  def pickup_location
    [ pickup_x, pickup_y ]
  end

  def dropoff_location
    [ dropoff_x, dropoff_y ]
  end

  # Driver management
  def assign_driver(driver_id)
    self.driver_id = driver_id
    self.status = ASSIGNED
    self.assigned_at = Time.current
  end

  def set_pending_driver_response(driver_id)
    self.driver_id = driver_id
    self.status = PENDING_DRIVER_RESPONSE
  end

  def reject_by_driver(driver_id)
    rejected_ids = JSON.parse(rejected_driver_ids)
    rejected_ids << driver_id unless rejected_ids.include?(driver_id)
    self.rejected_driver_ids = rejected_ids.to_json
    self.rejection_count += 1
    self.driver_id = nil
    self.status = WAITING
  end

  def driver_rejected?(driver_id)
    rejected_ids = JSON.parse(rejected_driver_ids)
    rejected_ids.include?(driver_id)
  end

  def start_pickup
    self.status = DRIVER_EN_ROUTE
  end

  def driver_arrive_at_pickup
    self.status = DRIVER_ARRIVED
  end

  def pick_up_rider
    self.status = RIDER_PICKED_UP
    self.picked_up_at = Time.current
  end

  def complete_ride
    self.status = COMPLETED
    self.completed_at = Time.current
  end

  def mark_as_failed
    self.status = FAILED
  end

  def mark_as_rejected
    self.status = REJECTED
  end

  def to_h
    {
      id: id,
      rider_id: rider_id,
      pickup_x: pickup_x,
      pickup_y: pickup_y,
      dropoff_x: dropoff_x,
      dropoff_y: dropoff_y,
      status: status,
      driver_id: driver_id,
      created_at: created_at,
      assigned_at: assigned_at,
      picked_up_at: picked_up_at,
      completed_at: completed_at,
      rejection_count: rejection_count
    }
  end
end
