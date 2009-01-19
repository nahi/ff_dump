#!/usr/local/bin/ruby

require 'httpclient'
require 'json'
require 'xsd/mapping'
require 'fileutils'
require 'logger'

def usage
  "#{$0} nickname remote_api_key dump_dir"
end

USER = ARGV.shift or raise usage
REMOTE_KEY = ARGV.shift or raise usage
DUMP_DIR = ARGV.shift or raise usage

FileUtils.mkdir_p(DUMP_DIR)

FF_LOGIN_URL = 'https://friendfeed.com/account/login'
FF_PAGE_URL = "http://friendfeed.com/#{USER}"
FF_DISCUSSION_URL = "http://friendfeed.com/#{USER}/discussion"
FF_ENTRY_URL = 'http://friendfeed.com/api/feed/entry'

logger = Logger.new($0 + '.log')

client = HTTPClient.new
client.debug_dev = logger
client.set_cookie_store('cookie.dat')

api_client = HTTPClient.new
api_client.debug_dev = logger
api_client.www_auth.basic_auth.challenge(URI.parse(FF_ENTRY_URL), true)
api_client.set_auth(nil, USER, REMOTE_KEY)

[FF_PAGE_URL, FF_DISCUSSION_URL].each do |scrape_url|
  30.step(700, 30) do |idx|
    body = client.get_content(scrape_url + "?start=#{idx}")
    eids = body.scan(/ eid="([^"]+)"/).collect { |eid| eid[0] }
    entry_url = FF_ENTRY_URL + '?entry_id=' + eids.join(',')
    JSON.parse(api_client.get_content(entry_url))['entries'].each do |entry|
      published = entry['published']
      id = entry['id']
      filename = File.join(DUMP_DIR, "#{published}_#{id}")
      File.open(filename, 'w') do |f|
        f.write(XSD::Mapping.obj2xml(entry, 'entry'))
      end
    end
    sleep 30
  end
end
