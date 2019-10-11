require 'gooddata'
require 'gooddata_connectors_base'
require 'sequel'

require 'gooddata_connectors_downloader_sql/version'
require 'gooddata_connectors_downloader_sql/sql'

module GoodData
  module Connectors
    module DownloaderSql
      # Middleware wrapper of SqlDownloader
      class SqlDownloaderMiddleWare < GoodData::Bricks::Middleware
        def call(params)
          # Setup logger
          $log = params['GDC_LOGGER']
          $log.info "Initializing #{self.class.to_s.split('::').last}" if $log

          # Create downloader instance
          downloader = Sql.new(params['metadata_wrapper'], params)

          # Call implementation
          @app.call(params.merge('sql_downloader_wrapper' => downloader))
        end
      end
    end
  end
end
