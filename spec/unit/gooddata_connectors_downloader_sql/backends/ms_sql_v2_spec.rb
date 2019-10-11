require 'gooddata_connectors_downloader_sql'

describe GoodData::Connectors::DownloaderSql::Backend::MsSql2 do
  ENTITY_NAME = 'Event'.freeze
  Entity = GoodData::Connectors::Metadata::Entity
  Field = GoodData::Connectors::Metadata::Field

  let(:metadata) do
    GoodData::Connectors::Metadata::Metadata.new(GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
  end

  let(:obj) do
    obj = GoodData::Connectors::DownloaderSql::Backend::MsSql2.new(metadata)
    obj.connection_options = {
      'server' => 'svs-82-mssql.cmklrh2wh3es.us-east-1.rds.amazonaws.com:1433',
      'database' => 'gd_test',
      'username' => 'gooddata',
      'password' => ENV['GD_TEST_MSSQL_PASS']
    }
    obj
  end

  it 'Is defined' do
    expect(GoodData::Connectors::DownloaderSql::Backend::MsSql2)
    expect(GoodData::Connectors::DownloaderSql::Backend::MsSql2).to be_kind_of(Class)
  end

  describe '#create_connection' do
    it 'Creates connection without fetch size' do
      obj.create_connection
      expect(obj.db).to be_instance_of(Sequel::JDBC::Database)
    end
  end

  describe '#load_db_fields' do
    it 'Loads fields' do
      obj.create_connection
      fields = obj.load_db_fields(ENTITY_NAME)
      expect(fields.map { |field| field.type.type }).to eq %w(integer decimal date string string string decimal decimal)
    end
  end

  describe '#download_data' do
    it 'Downloads data' do
      obj.create_connection
      field1_hash = {
        'id' => 'id',
        'name' => 'id',
        'order' => 'g1',
        'type' => 'integer-true',
        'custom' => {},
        'enabled' => true
      }
      field1 = Field.new('hash' => field1_hash)
      field2_hash = {
        'id' => 'text',
        'name' => 'text',
        'order' => 'g2',
        'type' => 'string-255',
        'custom' => {},
        'enabled' => true
      }
      field2 = Field.new('hash' => field2_hash)
      fields = [field1, field2]
      hash = {
        'id' => ENTITY_NAME,
        'name' => ENTITY_NAME,
        'version' => 'default',
        'type' => 'type',
        'custom' => {},
        'enabled' => true
      }
      entity = Entity.new('hash' => hash)
      allow(entity).to receive(:get_enabled_fields_objects).and_return fields

      obj.download_data(entity)
      expect(Zlib::GzipReader.open("tmp/#{ENTITY_NAME}.csv.gz").readlines[0]).to eq "id,text\n"
      File.delete("tmp/#{ENTITY_NAME}.csv.gz")
    end
  end
end
