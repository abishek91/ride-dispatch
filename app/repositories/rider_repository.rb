# Repository for managing riders in memory
class RiderRepository < BaseRepository
  def find_riders_at_location(x, y)
    where { |rider| rider.pickup_x == x && rider.pickup_y == y }
  end

  def find_riders_by_dropoff_location(x, y)
    where { |rider| rider.dropoff_x == x && rider.dropoff_y == y }
  end

  def statistics
    all_riders = all
    {
      total: all_riders.count
    }
  end
end
