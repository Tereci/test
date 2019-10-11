# encoding: utf-8

require 'gooddata_connectors_base/downloaders/base_downloader'

require_relative 'backends/backends'
require_relative 'extensions/extensions'

module GoodData
  module Connectors
    module DownloaderSql
      class Sql < Base::BaseDownloader
        attr_accessor :backend
        TYPE = 'sql'.freeze

        def initialize(metadata, options = {})
          super(metadata, options)
          $now = GoodData::Connectors::Metadata::Runtime.now
        end

        def validation_schema
          File.join(File.dirname(__FILE__), 'schema/validation_schema.json')
        end

        class << self
          def create_backend(class_type, options, metadata)
            class_name = "#{GoodData::Connectors::DownloaderSql::Backend}::#{class_type}"
            klass = Object.class_from_string(class_name)
            backend = klass.new(metadata, options)
            backend.create_connection
            backend
          end
        end

        def validation_schema
          File.join(File.dirname(__FILE__), 'schema/validation_schema.json')
        end


        def connect
          puts 'Connecting to storage with input CSVs'
          database_type = @metadata.get_configuration_by_type_and_key(TYPE, 'type')
          options = @metadata.get_configuration_by_type_and_key(TYPE, 'options')
          @backend = Sql.create_backend(database_type, options['connection'], @metadata)
        end

        def load_metadata(entity_name)
          metadata_entity = @metadata.get_entity(entity_name)
          schema = get_schemas(metadata_entity).first.first
          query = metadata_entity.custom['query']
          temporary_fields = query ? @backend.get_fields_from_config(metadata_entity, schema) : @backend.load_db_fields(metadata_entity, schema)
          diff = metadata_entity.diff_fields(temporary_fields)

          # Merging entity fields
          add_fields(metadata_entity, diff) if @metadata.load_fields_from_source?(metadata_entity.id)
          disable_fields(metadata_entity, diff)
          change_fields(metadata_entity, diff)

          set_custom_metadata(metadata_entity)
          metadata.save_entity(metadata_entity)
        end

        def download_entity_data(entity_name)
          metadata_entity = @metadata.get_entity(entity_name)
          options = @metadata.get_configuration_by_type_and_key(TYPE, 'options')
          number_of_threads = metadata.get_configuration_by_type_and_key(TYPE, 'options|number_of_schemas_threads', Integer, 1)
          partial_full = metadata_entity.custom['partial_full_load_field']
          full_load = @metadata.get_entity_configuration_by_type_and_key(metadata_entity, TYPE, 'options|full', Boolean, true)
          schemas = get_schemas(metadata_entity)
          semaphore = Mutex.new
          schemas.peach(number_of_threads) do |schema, schema_name|
            $log.info "Downloading #{entity_name} from schema #{schema} (#{schema_name})" if schema
            client_id = schema_name
            try_count = 0
            begin
              file = @backend.download_data(metadata_entity, options, schema)
            rescue Sequel::Error => e
              raise e if e.to_s.include?('OutOfMemoryError')
              $log.warn "Error #{e} occured. Retrying..."
              try_count += 1
              retry unless try_count > 3
              raise e
            end
            semaphore.synchronize do
              $log.info "Client ID for file #{file} is #{client_id}"
              metadata_entity.store_runtime_param('full', full_load)
              metadata_entity.store_runtime_param('schema', client_id) if client_id
              metadata_entity.store_runtime_param('target_predicate', 'true') if partial_full
              metadata_entity.store_runtime_param('source_filename', file)
              response = @metadata.save_data(metadata_entity)
              raise 'There was an error saving data to S3' unless response[:status] == :ok
            end
            File.delete(file)
          end
        end

        def get_schemas(metadata_entity)
          schemas = metadata_entity.custom['schema']
          schemas = @metadata.get_configuration_by_type_and_key(TYPE, 'options|connection|schema') unless schemas
          schema_sql = metadata_entity.custom['schema_sql']
          schema_sql = @metadata.get_configuration_by_type_and_key(TYPE, 'options|connection|schema_sql') unless schema_sql
          schemas = get_schemas_from_sql(schema_sql) if schema_sql
          schemas = [schemas] unless schemas.is_a?(Array)
          schemas.map{|schema| schema.is_a?(Array) ? schema : [schema,schema]}
        end

        def get_schemas_from_sql(sql)
          @backend.db[sql].map{|entry| entry.values.length > 1 ? entry.values : [entry.values[0],entry.values[0]]}.select{|x,y| x}
        end

        # TODO: Implement
        def define_default_entities
          []
        end

        private

        def add_fields(metadata_entity, diff)
          diff['only_in_target'].each do |target_field|
            # The field is not in current entity, we need to create it
            $log.info "Adding new field #{target_field.name} to entity #{metadata_entity.id}"
            target_field.order = metadata_entity.get_new_order_id
            metadata_entity.add_field(target_field)
            metadata_entity.make_dirty
          end
        end

        def disable_fields(metadata_entity, diff)
          diff['only_in_source'].each do |source_field|
            next if source_field.disabled?
            $log.info "Disabling field #{source_field.name} in entity #{metadata_entity.id}"
            source_field.disable('From synchronization with source system')
            metadata_entity.make_dirty
          end
        end

        def change_fields(metadata_entity, diff)
          diff['changed'].each do |change|
            source_field = change['source_field']
            $log.info "The field #{source_field.name} in entity #{metadata_entity.id} has changed"
            # source_field.name = change["target_field"].name if change.include?("name")
            raise Exception, "The type in data structure file for field #{source_field.name} for entity #{metadata_entity.id} has changed. This is not supported in current version of SQL connector" if change.include?('type')
            metadata_entity.make_dirty
          end
        end

        def set_custom_metadata(metadata_entity)
          if !metadata_entity.custom.include?('download_by') || (metadata_entity.custom['download_by'] != TYPE)
            metadata_entity.custom['download_by'] = TYPE
            metadata_entity.make_dirty
          end

          if !metadata_entity.custom.include?('file_format') || (metadata_entity.custom['file_format'] != 'GZIP')
            metadata_entity.custom['file_format'] = 'GZIP'
            metadata_entity.make_dirty
          end

          if !metadata_entity.custom.include?('enclosed_by') || (metadata_entity.custom['enclosed_by'] != '"')
            metadata_entity.custom['enclosed_by'] = '"'
            metadata_entity.make_dirty
          end

          if !metadata_entity.custom.include?('escape_as') || (metadata_entity.custom['escape_as'] != '"')
            metadata_entity.custom['escape_as'] = '"'
            metadata_entity.make_dirty
          end
        end
      end
    end
  end
end
