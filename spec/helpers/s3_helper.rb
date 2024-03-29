
require 'aws-sdk-v1'

module GoodData
  module Connectors
    module DownloaderSql
      module S3Helper
        class << self
          def connect
            args = {
              access_key_id: GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_BDS_ACCESS_KEY,
              secret_access_key: GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_BDS_SECRET_KEY,
              max_retries: 15,
              http_read_timeout: 120,
              http_open_timeout: 120
            }

            @s3 = AWS::S3.new(args)
            @bucket = @s3.buckets[GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_BDS_BUCKET]
          end

          def upload_file(from, to)
            obj = @bucket.objects[to]
            obj.write(File.open(from, 'rb'))
          end

          def download_files(from, to)
            list = @bucket.objects.with_prefix(from)
            list.each do |object|
              filename = object.key.split('/').last
              File.open(to + filename, 'w') do |f|
                f.write(object.read)
              end
            end
          end

          def exists?(path)
            @bucket.objects[path].exists?
          end

          def get_object(path)
            @bucket.objects[path]
          end

          def generate_remote_path(file)
            File.join(
              GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_BDS_FOLDER,
              GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_ACCOUNT,
              GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_TOKEN,
              file
            )
          end

          def copy_data_folder
            path = 'spec/data/files/data_folder/**/*'
            Dir.glob(path).each do |element|
              unless File.directory?(element)
                remote_path = generate_remote_path(File.join('data_path', element.split('/')[4..-1].join('/')))
                upload_file(element, remote_path)
              end
            end
          end

          def copy_batch_folder
            path = 'spec/data/files/batches/**/*'
            Dir.glob(path).each do |element|
              unless File.directory?(element)
                remote_path = generate_remote_path(File.join('batches', element.split('/')[4..-1].join('/')))
                upload_file(element, remote_path)
              end
            end
          end

          def delete_data_folder
            list = @bucket.objects.with_prefix(generate_remote_path('data_path'))
            list.each(&:delete)
          end

          # Delete contents of batches, metadata and data files on bucket
          def clear_data
            @bucket.objects.with_prefix(generate_remote_path('batches/')).delete_all
            @bucket.objects.with_prefix(generate_remote_path('metadata/')).delete_all
            @bucket.objects.with_prefix(generate_remote_path('sql_downloader_1/')).delete_all
            @bucket.objects.with_prefix(generate_remote_path('data_files/')).delete_all
          end

          def clear_token
            @bucket.objects.with_prefix(generate_remote_path('')).delete_all
          end
        end
      end
    end
  end
end
