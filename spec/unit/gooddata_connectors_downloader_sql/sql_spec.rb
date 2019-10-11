require 'aws-sdk-v1'
require 'gooddata_connectors_downloader_sql'

describe GoodData::Connectors::DownloaderSql::Sql do
  before :all do
    Sql = GoodData::Connectors::DownloaderSql::Sql
    Metadata = GoodData::Connectors::Metadata::Metadata
    Entity = GoodData::Connectors::Metadata::Entity
    Field = GoodData::Connectors::Metadata::Field
    TYPE = 'sql'.freeze
    ENTITY_NAME = 'Event'.freeze
    REMOTE_FOLDER = 'AIDAJFITXNOA7ZNFS3H4U_gdc-ms-connectors_ConnectorsTestSuite/WalkMe/data'.freeze
  end

  let(:metadata) do
    GoodData::Connectors::Metadata::Metadata.new(GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
  end

  let(:downloader) do
    downloader = GoodData::Connectors::DownloaderSql::Sql.new(metadata, GoodData::Connectors::DownloaderSql::ConnectionHelper::PARAMS)
    metadata.set_source_context(GoodData::Connectors::DownloaderSql::ConnectionHelper::DEFAULT_DOWNLOADER, {}, downloader)
    downloader.connect
    downloader
  end

  let(:entity) do
    hash = {
      'id' => ENTITY_NAME,
      'name' => ENTITY_NAME,
      'version' => 'default',
      'type' => 'type'
    }
    Entity.new('hash' => hash)
  end

  it 'Should be defined' do
    expect(Sql).to be_kind_of(Class)
  end

  describe 'new' do
    it 'Should initialize' do
      expect(downloader).to be_instance_of(Sql)
    end
  end

  describe '#create_backend' do
    before :each do
      @options = downloader.metadata.get_configuration_by_type_and_key('sql', 'options')
    end

    it 'Connects with MySql' do
      expect(Sql.create_backend('MySql', @options, downloader.metadata)).to be_instance_of(GoodData::Connectors::DownloaderSql::Backend::MySql)
    end

    it 'Connects with PostgreSql' do
      expect(Sql.create_backend('PostgreSql', @options, downloader.metadata)).to be_instance_of(GoodData::Connectors::DownloaderSql::Backend::PostgreSql)
    end

    it 'Connects with MsSql' do
      expect(Sql.create_backend('MsSql', @options, downloader.metadata)).to be_instance_of(GoodData::Connectors::DownloaderSql::Backend::MsSql)
    end

    it 'Connects unsuccesfully - unknown backend' do
      expect { Sql.create_backend('NoSql', @options, downloader.metadata) }.to raise_error(NameError)
    end
  end

  describe '#load_metadata' do
    before(:each) do
      hash = {
        'id' => ENTITY_NAME,
        'name' => ENTITY_NAME,
        'version' => 'default',
        'type' => 'type',
        'enabled' => true
      }
      field1_hash = {
        'id' => 'id_name',
        'name' => 'id_name',
        'order' => 'g1',
        'type' => 'integer-true',
        'custom' => {},
        'enabled' => true
      }
      field2_hash = {
        'id' => 'url',
        'name' => 'url',
        'order' => 'g2',
        'type' => 'string-255',
        'custom' => {},
        'enabled' => true
      }
      @field1 = Field.new('hash' => field1_hash)
      @field2 = Field.new('hash' => field2_hash)
      @entity = Entity.new('hash' => hash)
      @entity.custom = {}
    end

    it 'Returns entity, merges fields and changes custom metadata' do
      @entity.custom['enclosed_by'] = '/'
      @entity.custom['escape_as'] = '\\'
      allow(downloader.metadata).to receive(:get_entity).with(ENTITY_NAME)
        .and_return(@entity)
      allow(downloader.backend).to receive(:load_db_fields).with(ENTITY_NAME)
        .and_return([@field1, @field2])
      allow(downloader.metadata).to receive(:diff_fields).with([@field1, @field2])
        .and_return([])
      expect(downloader.load_metadata(ENTITY_NAME)).to eq @entity
      expect(@entity.custom['download_by']).to eq 'sql'
      expect(@entity.custom['file_format']).to eq 'GZIP'
      expect(@entity.custom['enclosed_by']).to eq '"'
      expect(@entity.custom['escape_as']).to eq '"'
    end

    it 'Returns entity and sets custom metadata' do
      allow(downloader.metadata).to receive(:get_entity).with(ENTITY_NAME)
        .and_return(@entity)
      allow(downloader.backend).to receive(:load_db_fields).with(ENTITY_NAME)
        .and_return([@field1, @field2])
      allow(downloader.metadata).to receive(:diff_fields).with([@field1, @field2])
        .and_return([])
      expect(downloader.load_metadata(ENTITY_NAME)).to eq @entity
      expect(@entity.custom['download_by']).to eq 'sql'
      expect(@entity.custom['file_format']).to eq 'GZIP'
      expect(@entity.custom['enclosed_by']).to eq '"'
      expect(@entity.custom['escape_as']).to eq '"'
    end
  end

  describe '#define_default_entities' do
    it 'Returns empty array' do
      arr = []
      expect(downloader.define_default_entities).to eq arr
    end
  end

  describe '#download_entity_data' do
    before :each do
      @options = downloader.metadata.get_configuration_by_type_and_key('sql', 'options')
      @entity = downloader.metadata.get_entity(ENTITY_NAME)
    end

    it 'Raises Exception if save is unsuccesful' do
      allow(downloader.backend).to receive(:download_data).with(@entity, @options)
        .and_return('filename')
      allow(downloader.metadata).to receive(:save_data).with(@entity)
        .and_return(status: :fail)
      expect { downloader.download_entity_data(ENTITY_NAME) }.to raise_error(RuntimeError)
    end

    it 'Downloads data' do
      allow(downloader.backend).to receive(:download_data).with(@entity, @options)
        .and_return('filename')
      allow(downloader.metadata).to receive(:save_data).with(@entity)
        .and_return(status: :ok)
      File.new('filename', 'w')
      downloader.download_entity_data(ENTITY_NAME)
      expect(@entity.runtime['global']['source_filename']).to eq 'filename'
    end
  end
end
