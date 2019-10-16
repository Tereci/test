# encoding: utf-8

#require_relative 'drivers/sqljdbc41.jar'
require_relative 'drivers/jtds.jar'

module GoodData
  module Connectors
    module DownloaderSql
      module Backend
        class MsSql2 < BaseBackend
          attr_accessor :db

          def create_connection
            $log.info @connection_options['con_string']
            @db = Sequel.connect(@connection_options['con_string'], user: @connection_options['username'], password: @connection_options['password'], selectMethod: 'cursor', packetSize: 0)
            @db.loggers << Logger.new($stdout)
          end

          # rubocop:disable MethodLength
          def load_db_fields(metadata_entity, schema = nil)
            entity_name = metadata_entity.name
            sys_response = @db[:sysobjects].filter(type: %w(u v), name: entity_name)
            raise Exception, "There is view and table name with same name in DB. This is not supported by SQL downloader #{entity_name}" if sys_response.count > 1
            system_id = sys_response.first[:id]

            metadata_fields = []
            columns_response = @db[:syscolumns].filter(id: system_id)
            columns_response.each do |column|
              case column[:type]

                # Integer
              when 63, 48, 52, 59, 56, 38
                type = 'integer'
                # Varchar - 9
                # Char - 8
                # Type Text have strangly filled lenght param
              when 35
                type = 'string-255'
              when 47, 99, 37, 39, 45
                type = "string-#{column[:prec] <= 0 ? 255 : column[:prec]}"
                # Date
                # Timestamp
              when 61, 58, 111
                type = 'date-true'
                # Numeric - Decimal
              when 55, 63, 110, 122, 60
                type = "decimal-#{column[:prec] + column[:scale]}-#{column[:scale]}"
              when 109
                type = 'decimal-16-4'
              when 50
                type = 'boolean'
              else
                $log.info "Unsupported database type #{column[:name]} - using string(255) as default value"
                type = 'string-255'
              end

              $log.info "Database type was #{column[:type]} converted to #{type}"
              config_field = metadata_entity.custom['fields'] ? metadata_entity.custom['fields'].find{|config_field| config_field['name'].casecmp(column[:name]).zero? } : nil
              name = config_field && config_field['ads_name'] || column[:name]
              field = Metadata::Field.new('id' => name,
                                          'name' => name,
                                          'type' => type,
                                          'custom' => {})
              metadata_fields << field
            end
            metadata_fields
          end
          # rubocop:enable MethodLength

          def download_data(metadata_entity, options = {}, schema = nil)
            entity_fields = metadata_entity.get_enabled_fields_objects
            row_number = 0
            $log.info 'Downloading data with MSSQL adapter'
            filename = get_filename(metadata_entity.id)
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

          def get_value(field, row)
            value = row[field.id.downcase.to_sym]
            return value unless field.type.instance_of?(Metadata::BooleanType)
            return nil if value.nil?
            value == 'true' || value == true ? 1 : 0
          end
        end
      end
    end
  end
end
