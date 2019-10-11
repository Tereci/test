require 'gooddata_connectors_downloader_sql'

describe GoodData::Connectors::DownloaderSql::Backend::BaseBackend do
  Sql = GoodData::Connectors::DownloaderSql::Sql
  Metadata = GoodData::Connectors::Metadata::Metadata
  Entity = GoodData::Connectors::Metadata::Entity
  Field = GoodData::Connectors::Metadata::Field
  TYPE = 'sql'.freeze
  ENTITY_NAME = 'Event'.freeze

  let(:metadata) do
    GoodData::Connectors::Metadata::Metadata.new(GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
  end

  let(:obj) do
    GoodData::Connectors::DownloaderSql::Backend::BaseBackend.new(metadata)
  end

  it 'Is defined' do
    expect(GoodData::Connectors::DownloaderSql::Backend::BaseBackend)
    expect(GoodData::Connectors::DownloaderSql::Backend::BaseBackend).to be_kind_of(Class)
  end

  describe '#create_connection' do
    it 'Raises NotImplemented' do
      expect { obj.create_connection }.to raise_error(NotImplementedError)
    end
  end

  describe '#load_db_fields' do
    it 'Raises NotImplemented' do
      expect { obj.create_connection }.to raise_error(NotImplementedError)
    end
  end

  describe '#pack_data' do
    it 'Compress data' do
      File.open("tmp/#{ENTITY_NAME}.csv", 'w') { |file| file.write('Lorem ipsum') }
      obj.pack_data(ENTITY_NAME)
      expect(Zlib::GzipReader.open("tmp/#{ENTITY_NAME}.csv.gz").readlines[0]).to eq 'Lorem ipsum'
    end
  end

  describe '#create_result_set' do
    before :each do
      hash = {
        'id' => ENTITY_NAME,
        'name' => ENTITY_NAME,
        'version' => 'default',
        'type' => 'type',
        'custom' => {},
        'enabled' => true
      }
      @entity = Entity.new('hash' => hash)
      db = Object.new
      @db_entity = Object.new
      @db_entity2 = Object.new
      allow(@db_entity2).to receive(:first).and_return('OK')
      allow(db).to receive(:from).with(@entity.id.to_sym).and_return @db_entity
      allow(db).to receive(:[]).with("SELECT * FROM schema.\"#{ENTITY_NAME}\"")
        .and_return @db_entity2
      obj.db = db
    end

    after :each do
      File.delete("tmp/#{ENTITY_NAME}.csv.gz") if File.exist?("tmp/#{ENTITY_NAME}.csv.gz")
    end

    it 'Downloads data and sets runtime metadata full' do
      expect(obj.create_result_set(@entity)).to eq @db_entity
      expect(@entity.runtime['global']['full']).to eq true
    end

    it 'Downloads data from default start date with schema' do
      start_date = '2010-01-01'
      @entity.custom['timestamp'] = 'timestamp'
      allow(@db_entity2).to receive(:where)
        .with('timestamp >= ? and timestamp < ?', Time.parse(start_date), GoodData::Connectors::Metadata::Runtime.now)
        .and_return('where OK')
      expect(obj.create_result_set(@entity, {}, 'schema')).to eq 'where OK'
      expect(@entity.runtime['global']['date_from']).to eq Time.parse(start_date)
      expect(@entity.runtime['global']['date_to']).to eq GoodData::Connectors::Metadata::Runtime.now
      expect(@entity.runtime['global']['full']).to be_falsey
    end

    it 'Downloads data from given start date' do
      start_date = '2017-01-01'
      @entity.custom['timestamp'] = 'timestamp'
      allow(@db_entity2).to receive(:where)
        .with('timestamp >= ? and timestamp < ?', Time.parse(start_date), GoodData::Connectors::Metadata::Runtime.now)
        .and_return('where OK')
      expect(obj.create_result_set(@entity, { 'default_start_date' => start_date }, 'schema')).to eq 'where OK'
      expect(@entity.runtime['global']['date_from']).to eq Time.parse(start_date)
      expect(@entity.runtime['global']['date_to']).to eq GoodData::Connectors::Metadata::Runtime.now
      expect(@entity.runtime['global']['full']).to be_falsey
    end

    it 'Downloads data from last run' do
      start_date = '2015-11-13'
      @entity.previous_runtime = { 'date_to' => start_date }
      @entity.custom['timestamp'] = 'timestamp'
      allow(@db_entity2).to receive(:where)
        .with('timestamp >= ? and timestamp < ?', Time.parse(start_date), GoodData::Connectors::Metadata::Runtime.now)
        .and_return('where OK')
      expect(obj.create_result_set(@entity, {}, 'schema')).to eq 'where OK'
      expect(@entity.runtime['global']['date_from']).to eq Time.parse(start_date)
      expect(@entity.runtime['global']['date_to']).to eq GoodData::Connectors::Metadata::Runtime.now
      expect(@entity.runtime['global']['full']).to be_falsey
    end
  end
end
