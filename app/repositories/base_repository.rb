# Base repository class providing common CRUD operations
class BaseRepository
  def initialize
    @storage = {}
  end

  def create(entity)
    @storage[entity.id] = entity
    entity
  end

  def find(id)
    @storage[id]
  end

  def all
    @storage.values
  end

  def update(entity)
    @storage[entity.id] = entity if @storage.key?(entity.id)
    entity
  end

  def delete(id)
    @storage.delete(id)
  end

  def exists?(id)
    @storage.key?(id)
  end

  def count
    @storage.size
  end

  def clear
    @storage.clear
  end

  protected

  def where(&block)
    @storage.values.select(&block)
  end

  def find_by(&block)
    @storage.values.find(&block)
  end
end
