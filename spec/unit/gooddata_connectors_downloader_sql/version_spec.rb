require 'gooddata_connectors_downloader_sql'

describe GoodData::Connectors::DownloaderSql do
  describe 'VERSION' do
    it 'Is defined' do
      expect(GoodData::Connectors::DownloaderSql::VERSION).to be_kind_of(String)
    end
  end
end
