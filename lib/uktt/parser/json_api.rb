module Uktt
  class Parser
    class JsonApi
      def initialize(body)
        @body = JSON.parse(body)
      end

      def parse
        if data.is_a?(Hash)
          parse_resource(data)
        elsif data.is_a?(Array)
          parse_collection(data)
        else
          data
        end
      end

      def errors
        @body['error'] || @body['errors']&.map { |error| error['detail'] }&.join(', ')
      end

      private

      def data
        @data = @body['data']
      end

      def parse_resource(resource)
        result = {}

        parse_top_level_attributes!(resource, result)

        parse_relationships!(resource['relationships'], result) if resource.key?('relationships')

        result
      end

      def parse_collection(collection)
        collection.map do |resource|
          parse_resource(resource)
        end
      end

      def parse_top_level_attributes!(attributes, parent)
        parent.merge!(attributes['attributes'])
      end

      def parse_relationships!(relationships, parent)
        relationships.each do |name, values|
          parent[name] = if values['data'].is_a?(Array)
                           values['data'].map do |v|
                             record = find_included(v['id'], v['type'])
                             parse_record(record)
                           end
                         elsif values['data'].is_a?(Hash)
                           record = find_included(values['data']['id'], values['data']['type'])
                           parse_record(record)
                         else
                           values['data']
                         end
        end
      end

      def parse_record(record)
        record_attrs = record['attributes'].clone || {}
        if record.key?('relationships')
          parse_relationships!(record['relationships'], record_attrs)
        end
        record_attrs
      end

      def find_included(id, type)
        @body['included']&.find { |r| r['id'].to_s == id.to_s && r['type'].to_s == type.to_s } || {}
      end
    end
  end
end
