module TinyClient
  # Mixin that add support for limit/offset pagination to {TinyClient::Resource}
  module PaginationSupport
    def self.included(resource_class)
      raise ArgumentError, 'Works only for TinyClient::Resource' unless resource_class <= Resource
      resource_class.extend(ClassMethods)
    end

    # Add methods that allows to walk fully through collections thanks to limit/offset pagination.
    # All methods return an enumerator that will query the server in batch based on the limit size
    # and total number of items.
    module ClassMethods
      # Similar to {Resource.index} but return all resources available at this path.
      # It use limit and offset
      # params to retrieved all resources. ( buffered by the limit size)
      def index_all(params = {})
        get_all(params)
      end

      # Similar to {index_all}, the return enumerator will yield on the buffered ( limit )
      # rather than each element.
      def index_in_batches(params = {})
        get_in_batches(params)
      end

      def get_all(params = {}, id = nil, name = nil, resource_class = nil)
        Enumerator.new do |y|
          count = limit = params.fetch(:limit, @conf.limit || 100)
          offset = params.fetch(:offset, 0)
          while limit == count
            inner = get(params.merge(limit: limit, offset: offset), id, name, resource_class)
            loop { y << inner.next }
            offset += limit
            count = inner.count
          end
        end
      end

      def get_in_batches(params = {}, id = nil, name = nil, resource_class = nil)
        Enumerator.new do |y|
          count = limit = params.fetch(:limit, @conf.limit || 100)
          offset = params.fetch(:offset, 0)
          while limit == count
            inner = get(params.merge(limit: limit, offset: offset), id, name, resource_class)
            loop { y << inner }
            offset += limit
            count = inner.count
          end
        end
      end
    end
  end
end
