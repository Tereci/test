require 'gooddata_connectors_downloader_sql'

describe GoodData::Connectors::DownloaderSql::SqlDownloaderMiddleWare do
  it 'Is defined' do
    expect(GoodData::Connectors::DownloaderSql::SqlDownloaderMiddleWare).to be_truthy
  end
end
