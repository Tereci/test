# encoding: utf-8
require_relative 'drivers/postgresql-9.4.1212.jre6.jar'

module GoodData
  module Connectors
    module DownloaderSql
      module Backend
        class PostgreSql < BaseBackend
          attr_accessor :db

          def create_connection
            fetch_size = @connection_options.include?('fetch_size') ? @connection_options['fetch_size'] : nil
            @db = Sequel.connect("jdbc:postgresql://#{@connection_options['server']}/#{@connection_options['database']}?zeroDateTimeBehavior=convertToNull&characterEncoding=UTF-8&characterSetResults=UTF-8", user: @connection_options['username'], password: @connection_options['password'], selectMethod: 'cursor', packetSize: 0, fetch_size: fetch_size)
          end

          def load_db_fields(metadata_entity, schema = nil)
            entity_name = metadata_entity.name
            metadata_fields = []
            db_schema = schema || 'public'
            $log.info "Downloading fields for entity #{entity_name}"
            columns_response = @db["SELECT * FROM information_schema.columns WHERE LOWER(table_name)='#{entity_name.downcase}' AND table_schema='#{db_schema}'"]

            columns_response.each do |column|
              config_field = metadata_entity.custom['fields'] ? metadata_entity.custom['fields'].find{|config_field| config_field['name'].casecmp(column[:column_name]).zero? } : nil
              name = config_field && config_field['ads_name'] || column[:column_name]
              field = Metadata::Field.new('id' => name,
                                          'name' => name,
                                          'type' => get_column_type(column),
                                          'custom' => {})
              metadata_fields << field
            end
            metadata_fields
          end

          # rubocop:disable MethodLength
          def get_column_type(column)
            type = ''
            case column[:data_type]
              # Integer
            when 'integer', 'bigint', 'smallint', 'serial', 'bigserial'
              type = 'integer'
            when 'varchar', 'character', 'char', 'character varying'
              type = "string-#{column[:character_maximum_length] || 255}"
              # Date
            when 'text'
              type = 'string-255'
              $log.warn "The column #{column[:column_name]} is of type text. It will be truncated to 255 characters"
              # Timestamp
            when 'date'
              type = 'date-false'
            when 'timestamp', 'timestamp without time zone', 'timestamp with time zone'
              type = 'date-true'
              # Numeric - Decimal
            when 'time', 'time without time zone', 'time with time zone'
              type = 'time'
            when 'decimal', 'numeric'
              type = "decimal-#{column[:numeric_precision] || 16}-#{column[:numeric_scale] || 4}"
            when 'double precision','real'
              type = 'decimal-16-4'
            when 'boolean', 'tinyint'
              type = 'boolean'
            else
              $log.info "Unsupported database type #{column[:column_name]} - using string(255) as default value"
              type = 'string-255'
            end
            $log.info "Database type was #{column[:data_type]} converted to #{type}"
            type
          end
          # rubocop:enable MethodLength

          def download_data(metadata_entity, options = {}, schema = nil)
            db_schema = schema || 'public'
            entity_fields = metadata_entity.get_enabled_fields_objects
            row_number = 0
            filename = get_filename(metadata_entity.id)
            $log.info 'Downloading data with PostgreSQL adapter'
            CSV.open("tmp/#{filename}.csv", 'w', write_headers: true, headers: entity_fields.map(&:id)) do |csv|
              create_result_set(metadata_entity, options, db_schema).each_with_index do |row, i|
                csv << entity_fields.map do |field|
                  get_value(field, row)
                end
                $log.info "Downloaded #{i + 1} rows..." if ((i + 1) % 50_000).zero?
                row_number = i
              end
              $log.info "The file contains #{row_number + 1} rows"
            end
            pack_data(filename)
          end
        end
      end
    end
  end
end
