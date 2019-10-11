# encoding: utf-8
require 'securerandom'
require 'pry'
module GoodData
  module Connectors
    module DownloaderSql
      module Backend
        class BaseBackend
          attr_accessor :connection_options, :db, :metadata, :schema

          DEFAULT_PAGINATION_LIMIT = 500_000
          DEFAULT_START_DATE = '2010-01-01'.freeze
          DOWNLOADER_ID = 'downloader_id'.freeze

          def initialize(metadata, opts = {})
            @connection_options = opts
            @metadata = metadata
          end

          def create_connection
            raise NotImplementedError, 'The method need to be implemented by child'
          end

          def load_db_fields(_entity_name)
            raise NotImplementedError, 'The method need to be implemented by child'
          end

          def get_fields_from_config(metadata_entity, schema)
            entity_query = get_entity_custom_query(metadata_entity, schema)
            query = @db["SELECT * FROM (#{entity_query}) t WHERE 1=0"]
            columns = query.columns.map(&:to_s)
            metadata_fields = []
            columns.each do |column|
              config_field = metadata_entity.custom['fields'] ? metadata_entity.custom['fields'].find{|config_field| config_field['name'].casecmp(column).zero? } : nil
              name = config_field && config_field['ads_name'] || column
              field = Metadata::Field.new('id' => name,
                                          'name' => name,
                                          'type' => config_field ? get_field_type(metadata_entity, config_field) : 'string-255',
                                          'custom' => {})
              metadata_fields << field
            end
            metadata_fields
          end

          def get_field_type(metadata_entity, field)
            case field['type'].downcase
            when /^varchar\((\d*)\)/
              return "string-#{Regexp.last_match(1)}"
              when /^varchar-(\d*)/
                return "string-#{Regexp.last_match(1)}"
            when /^string-(\d*)/
              return "string-#{Regexp.last_match(1)}"
            when /^string\((\d*)\)/
              return "string-#{Regexp.last_match(1)}"
            when 'string', 'Varchar', 'varchar'
              return 'string-255'
            when 'integer', 'bigint'
              return 'integer'
            when 'numeric'
              return 'decimal-16-4'
            when /^decimal\((\d*),(\d*)\)/
              return "decimal-#{Regexp.last_match(1)}-#{Regexp.last_match(2)}"
            when /^decimal-(\d*)-(\d*)/
              return "decimal-#{Regexp.last_match(1)}-#{Regexp.last_match(2)}"
            when /^numeric-(\d*)-(\d*)/
              return "decimal-#{Regexp.last_match(1)}-#{Regexp.last_match(2)}"
            when /^numeric\((\d*),\s{0,1}(\d*)\)/
              return "decimal-#{Regexp.last_match(1)}-#{Regexp.last_match(2)}"
            when 'boolean'
              return 'boolean'
            when 'date', 'time-false'
              return 'date-false'
            when 'time-true', 'datetime'
              return 'date-true'
            when 'timestamp', 'timestamp without time zone'
              return 'timestamp'
            when 'time'
              return 'time'
            else
              raise "Unsupported type #{field['type']} for entity #{metadata_entity.id} and attribute #{field['name']}"
            end
          end


          def download_data(metadata_entity)
            entity_fields = metadata_entity.get_enabled_fields_objects

            CSV.open("tmp/#{metadata_entity.id}.csv", 'w', write_headers: true, headers: entity_fields.map(&:id)) do |csv|
              @db[metadata_entity.id.to_sym].each do |row|
                csv << entity_fields.map { |field| row[field.id.downcase.to_sym] }
              end
            end
            pack_data(metadata_entity.id)
          end

          def pack_data(file_name)
            gzip = "tmp/#{file_name}.csv.gz"
            orig = "tmp/#{file_name}.csv"
            `gzip #{orig}`
            gzip
          end

          def get_filename(name)
            "#{name}_#{SecureRandom.urlsafe_base64(6)}"
          end

          def get_start_date(metadata_entity, options)
            previous_runtime = metadata_entity.previous_runtime
            return Time.parse(previous_runtime['date_to']) if previous_runtime&.include?('date_to')
            return Time.at(previous_runtime['start_date']['timestamp'].to_i) if previous_runtime && previous_runtime.dig('start_date','timestamp')
            return Time.parse(options['default_start_date']) if options.include?('default_start_date')
            Time.parse(DEFAULT_START_DATE)
          end

          def get_db_entity(metadata_entity, schema)
            query = get_entity_custom_query(metadata_entity, schema)
            return @db[query] if query
            return @db.from(metadata_entity.id.to_sym) unless schema
            @db["SELECT * FROM #{schema}.\"#{metadata_entity.id}\""]
          end

          def create_result_set(metadata_entity, options = {}, schema = nil)
            now = GoodData::Connectors::Metadata::Runtime.now
            start_date = get_start_date(metadata_entity, options)
            db_entity = get_db_entity(metadata_entity, schema)
            type = DownloaderSql::Sql::TYPE
            full_load = @metadata.get_entity_configuration_by_type_and_key(metadata_entity, type, 'options|full', Boolean, true)
            debug = @metadata.get_configuration_by_type_and_key('global', 'debug', Boolean, false)
            $log.info "Found #{db_entity.count} rows in table, downloading..." if debug
            if metadata_entity.custom.include?('timestamp')
              timestamp_field = metadata_entity.custom['timestamp']

              metadata_entity.store_runtime_param('date_from', start_date)
              metadata_entity.store_runtime_param('date_to', now)
              $log.info "Running in incremental mode (from -> #{start_date},to -> #{now})"
              # monkey patch for bug in sequel
              if self.class == PostgreSql && schema
                entity_query = get_entity_custom_query(metadata_entity, schema)
                return @db["SELECT * FROM (#{entity_query}) t WHERE t.\"#{timestamp_field}\" >= '#{start_date}' and t.\"#{timestamp_field}\" < '#{now}'"] if entity_query
                db_entity = @db["SELECT * FROM #{schema}.\"#{metadata_entity.id}\" WHERE \"#{timestamp_field}\" >= '#{start_date}' and \"#{timestamp_field}\" < '#{now}'"]
              else
                db_entity = db_entity.where("#{timestamp_field} >= ? and #{timestamp_field} < ?", start_date, now)
              end
              db_entity
            else
              if full_load
                $log.info 'Running in full mode'
              else
                $log.info 'Running in incremental mode (set by configuration)'
              end
              db_entity
            end
          end

          def get_entity_custom_query(metadata_entity, schema = nil)
            query = metadata_entity.custom['query']
            return nil unless query
            first_schema = metadata_entity.custom['schema'].is_a?(Array) ? metadata_entity.custom['schema'].first : metadata_entity.custom['schema']
            schema ||= first_schema
            return query.gsub('${schema}',schema) if schema
            query
          end

          def get_value(field, row)
            value = row[field.name.to_sym]
            return value unless field.type.instance_of?(Metadata::BooleanType)
            return nil if value.nil?
            value == 'true' || value == true ? 1 : 0
          end
        end
      end
    end
  end
end
