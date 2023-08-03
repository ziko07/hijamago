require 'webmock'
include WebMock::API # rubocop:disable Style/MixinUsage
WebMock.enable!

require 'webmock/rspec'
allowed_sites = lambda do |uri|
  whitelist = ['127.0.0.1', '::1', 'localhost', 'graph.facebook.com', 'chromedriver.storage.googleapis.com', 'static.xx.fbcdn.net']
  if ENV['REAL_STRIPE']
    whitelist << 'api.stripe.com'
    whitelist << 'js.stripe.com'
  end
  whitelist.include?(uri.host) || uri.host =~ /(scontent|static)[.\w-]+\.fbcdn.net/
end
WebMock.disable_net_connect!(allow: allowed_sites)
