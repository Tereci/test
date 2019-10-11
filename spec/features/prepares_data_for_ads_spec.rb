require 'gooddata_connectors_downloader_sql'

describe 'Downloading data and preparing metadata, batch and files for ads integrator', type: :feature do
  before :all do
    Sql = GoodData::Connectors::DownloaderSql::Sql
    Metadata = GoodData::Connectors::Metadata::Metadata
    ConnectionHelper = GoodData::Connectors::DownloaderSql::ConnectionHelper
    S3Helper = GoodData::Connectors::DownloaderSql::S3Helper
  end

  before :each do
    FileUtils.mkdir_p('tmp/contractors')
    FileUtils.mkdir_p('tmp/Sales')
    FileUtils.mkdir_p('tmp/Event')
  end

  after :each do
    FileUtils.rm_rf('tmp')
    FileUtils.rm_rf('metadata')
    FileUtils.rm_rf('source')
    GoodData::Connectors::DownloaderSql::S3Helper.clear_data
  end

  it 'prepares data from MySql' do
    expected_metadata_contractors = File.open('spec/data/files/feature/expected_metadata_contractors.json').read
    expected_metadata_sales = File.open('spec/data/files/feature/expected_metadata_sales.json').read

    remote_config_path = S3Helper.generate_remote_path('configuration.json')
    S3Helper.upload_file('spec/data/configurations/configuration_1.json', remote_config_path)

    execute

    metadata_path = S3Helper.generate_remote_path('metadata/Sales/') + time_path
    S3Helper.download_files(metadata_path, 'tmp/Sales/')
    metadata = File.open(Dir['tmp/Sales/*_metadata.json'].first).read
    expect(metadata).to eq expected_metadata_sales

    metadata_path = S3Helper.generate_remote_path('metadata/contractors/') + time_path
    S3Helper.download_files(metadata_path, 'tmp/contractors/')
    metadata = File.open(Dir['tmp/contractors/*_metadata.json'].first).read
    expect(metadata).to eq expected_metadata_contractors

    files_path = S3Helper.generate_remote_path('sql_downloader_1/Sales/') + time_path
    S3Helper.download_files(files_path, 'tmp/Sales/')
    data = Zlib::GzipReader.open(Dir['tmp/Sales/*_data_*.gz'].first).read
    expect(data).to eq File.open('spec/data/files/feature/sales.csv').read

    files_path = S3Helper.generate_remote_path('sql_downloader_1/contractors/') + time_path
    S3Helper.download_files(files_path, 'tmp/contractors/')
    data = Zlib::GzipReader.open(Dir['tmp/contractors/*_data_*.gz'].first).read
    expect(data).to eq File.open('spec/data/files/feature/contractors.csv').read
  end

  it 'prepares data from MsSql' do
    expected_metadata_event = File.open('spec/data/files/feature/expected_metadata_event.json').read
    expected_event_data = File.open('spec/data/files/feature/event.csv').read

    remote_config_path = S3Helper.generate_remote_path('configuration.json')
    S3Helper.upload_file('spec/data/configurations/configuration_2.json', remote_config_path)

    execute(ENV['GD_TEST_MSSQL_PASS'])

    metadata_path = S3Helper.generate_remote_path('metadata/Event/') + time_path
    S3Helper.download_files(metadata_path, 'tmp/')
    metadata = File.open(Dir['tmp/*_metadata.json'].first).read
    expect(metadata).to eq expected_metadata_event

    files_path = S3Helper.generate_remote_path('sql_downloader_1/Event/') + time_path
    S3Helper.download_files(files_path, 'tmp/')
    data = Zlib::GzipReader.open(Dir['tmp/*_data_*.gz'].first).read
    expect(data).to eq expected_event_data
  end

  it 'prepares data from MsSql v2' do
    expected_metadata_event = File.open('spec/data/files/feature/expected_metadata_event2.json').read
    expected_event_data = File.open('spec/data/files/feature/event.csv').read

    remote_config_path = S3Helper.generate_remote_path('configuration.json')
    S3Helper.upload_file('spec/data/configurations/configuration_3.json', remote_config_path)

    execute(ENV['GD_TEST_MSSQL_PASS'])

    metadata_path = S3Helper.generate_remote_path('metadata/Event/') + time_path
    S3Helper.download_files(metadata_path, 'tmp/')
    metadata = File.open(Dir['tmp/*_metadata.json'].first).read
    expect(metadata).to eq expected_metadata_event

    files_path = S3Helper.generate_remote_path('sql_downloader_1/Event/') + time_path
    S3Helper.download_files(files_path, 'tmp/')
    data = Zlib::GzipReader.open(Dir['tmp/*_data_*.gz'].first).read
    expect(data).to eq expected_event_data
  end

  it 'prepares data from Postgres' do
    expected_metadata_event = File.open('spec/data/files/feature/expected_metadata_event3.json').read
    expected_event_data = File.open('spec/data/files/feature/event2.csv').read

    remote_config_path = S3Helper.generate_remote_path('configuration.json')
    S3Helper.upload_file('spec/data/configurations/configuration_4.json', remote_config_path)

    execute(ENV['GD_TEST_PSQL_PASS'])

    metadata_path = S3Helper.generate_remote_path('metadata/Event/') + time_path
    S3Helper.download_files(metadata_path, 'tmp/')
    metadata = File.open(Dir['tmp/*_metadata.json'].first).read
    expect(metadata).to eq expected_metadata_event

    files_path = S3Helper.generate_remote_path('sql_downloader_1/Event/') + time_path
    S3Helper.download_files(files_path, 'tmp/')
    data = Zlib::GzipReader.open(Dir['tmp/*_data_*.gz'].first).read
    expect(data).to eq expected_event_data
  end

  def time_path
    Time.now.strftime('%Y') + '/' + Time.now.strftime('%m') + '/' + Time.now.strftime('%d')
  end

  def execute(password = ENV['GD_TEST_MYSQL_PASS'])
    con_params = ConnectionHelper::PARAMS
    con_params['sql|options|connection|password'] = password
    metadata = Metadata.new(con_params)
    downloader = Sql.new(metadata, con_params)
    metadata.set_source_context(ConnectionHelper::DEFAULT_DOWNLOADER, {}, downloader)
    downloader.connect
    entities = metadata.get_downloader_entities_ids
    entities.each do |entity|
      downloader.load_metadata(entity)
      downloader.download_entity_data(entity)
    end
  end
end
