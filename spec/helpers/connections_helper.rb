
require 'aws-sdk-v1'

module GoodData
  module Connectors
    module DownloaderSql
      module Connections
        class << self
          def init
            @type = 'sql'
            @metadata = GoodData::Connectors::Metadata::Metadata.new(GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
            @downloader = GoodData::Connectors::DownloaderSql::Sql.new(@metadata, GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
            @metadata.set_source_context(GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_DOWNLOADER, {}, @downloader)
          end

          attr_reader :metadata

          attr_reader :downloader
        end
      end
    end
  end
end
