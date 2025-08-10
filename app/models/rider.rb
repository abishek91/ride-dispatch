# Represents a rider in the ride-hailing system
class Rider
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  # Attributes
  attribute :id, :string
  attribute :x, :integer  # Current location x coordinate
  attribute :y, :integer  # Current location y coordinate
  attribute :pickup_x, :integer
  attribute :pickup_y, :integer
  attribute :dropoff_x, :integer
  attribute :dropoff_y, :integer

  # Validations
  validates :id, presence: true
  validates :x, :y, :pickup_x, :pickup_y, :dropoff_x, :dropoff_y,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validate :pickup_and_dropoff_different

  def initialize(attributes = {})
    super
    self.id ||= SecureRandom.uuid
  end

  # Location methods
  def current_location
    [ x, y ]
  end

  def pickup_location
    [ pickup_x, pickup_y ]
  end

  def dropoff_location
    [ dropoff_x, dropoff_y ]
  end

  def move_to_dropoff
    self.x = dropoff_x
    self.y = dropoff_y
  end

  def at_location?(target_x, target_y)
    x == target_x && y == target_y
  end

  def to_h
    {
      id: id,
      x: x,
      y: y,
      pickup_x: pickup_x,
      pickup_y: pickup_y,
      dropoff_x: dropoff_x,
      dropoff_y: dropoff_y,
      current_location: current_location,
      pickup_location: pickup_location,
      dropoff_location: dropoff_location
    }
  end

  private

  def pickup_and_dropoff_different
    if pickup_x == dropoff_x && pickup_y == dropoff_y
      errors.add(:dropoff_x, "Pickup and dropoff locations cannot be the same")
    end
  end
end
