# encoding: utf-8
require_relative 'drivers/mysql-connector-java-5.1.35-bin.jar'

module GoodData
  module Connectors
    module DownloaderSql
      module Backend
        class MySql < BaseBackend
          attr_accessor :db

          def create_connection
            fetch_size = @connection_options.include?('fetch_size') ? @connection_options['fetch_size'] : 1000
            use_ssl = @connection_options['use_ssl']
            verify_server_certificate = @connection_options['verify_server_certificate']
            options = []
            options <<  'useSSL=true' if (use_ssl == true || use_ssl == 'true')
            options << "verifyServerCertificate=#{verify_server_certificate}" unless verify_server_certificate.nil?
            options << 'zeroDateTimeBehavior=convertToNull'
            options << 'characterEncoding=UTF-8'
            options << 'characterSetResults=UTF-8'
            options << 'useCursorFetch=true'
            options.compact!
            options = options.empty? ? '' : "?#{options.join('&')}"
            connection_validation_timeout = @connection_options['connection_validation_timeout']
            log_connection_info = @connection_options['log_connection_info'] == 'true' || @connection_options['log_connection_info'] == true
            @db = Sequel.connect("jdbc:mysql://#{@connection_options['server']}/#{@connection_options['database']}#{options}", user: @connection_options['username'], password: @connection_options['password'], selectMethod: 'cursor', packetSize: 0, fetch_size: fetch_size,convert_types: false, pool_timeout: 20, max_connections: 100, log_connection_info: log_connection_info)
            if connection_validation_timeout
              @db.extension(:connection_validator)
              @db.pool.connection_validation_timeout = connection_validation_timeout
            end
            @db_metadata = Sequel.connect("jdbc:mysql://#{@connection_options['server']}/information_schema#{options}", user: @connection_options['username'], password: @connection_options['password'])
          end

          # rubocop:disable MethodLength
          def load_db_fields(metadata_entity, schema = nil)
            entity_name = metadata_entity.name
            metadata_fields = []
            schema = schema || @connection_options['database']
            columns_response = @db_metadata[:COLUMNS].filter(TABLE_NAME: entity_name, TABLE_SCHEMA: schema)
            columns_response.each do |column|
              case column[:DATA_TYPE]

                # Integer
              when 'int', 'bigint', 'smallint'
                type = 'integer'
              when 'varchar'
                type = "string-#{column[:CHARACTER_MAXIMUM_LENGTH]}"
                # Date
              when 'longblob', 'longtext'
                type = 'string-255'
                $log.warn "The column #{column[:COLUMN_NAME]} for entity #{entity_name} is of type longblob or longtext. It will be truncated to 255 characters"
                # Timestamp
              when 'date'
                type = 'date-false'
              when 'datetime', 'timestamp'
                type = 'date-true'
                # Numeric - Decimal
              when 'time'
                type = 'time'
              when 'decimal'
                type = "decimal-#{column[:NUMERIC_PRECISION]}-#{column[:NUMERIC_SCALE]}"
              when 'boolean', 'tinyint'
                type = 'boolean'
              when 'double'
                type = 'decimal-16-4'
              else
                $log.info "Unsupported database type #{column[:COLUMN_NAME]} - using string(255) as default value"
                type = 'string-255'
              end
              $log.info "Database type was #{column[:DATA_TYPE]} converted to #{type}"
              config_field = metadata_entity.custom['fields'] ? metadata_entity.custom['fields'].find{|config_field| config_field['name'].casecmp(column[:COLUMN_NAME]).zero? } : nil
              name = config_field && config_field['ads_name'] || column[:COLUMN_NAME]
              field = Metadata::Field.new('id' => name,
                                          'name' => name,
                                          'type' => type,
                                          'custom' => {})
              metadata_fields << field
            end
            metadata_fields
          end
          # rubocop:enable MethodLength

          def get_db_entity(metadata_entity, schema)
            query = get_entity_custom_query(metadata_entity, schema)
            return @db[query] if query
            return @db.from(metadata_entity.id.to_sym) unless schema
            @db["SELECT * FROM `#{schema}`.`#{metadata_entity.id}`"]
          end

          def download_data(metadata_entity, options = {}, schema = nil)
            entity_fields = metadata_entity.get_enabled_fields_objects
            row_number = 0
            filename = get_filename(metadata_entity.id)
            $log.info 'Downloading data with MYSQL adapter'
            CSV.open("tmp/#{filename}.csv", 'w', write_headers: true, headers: entity_fields.map(&:id)) do |csv|
              create_result_set(metadata_entity, options, schema).each_with_index do |row, i|
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
