#!/usr/local/bin/ruby

require 'httpclient'
require 'json'
require 'xsd/mapping'
require 'fileutils'

def usage
  "#{$0} nickname remote_api_key dump_dir"
end

USER = ARGV.shift or raise usage
REMOTE_KEY = ARGV.shift or raise usage
DUMP_DIR = ARGV.shift or raise usage

FileUtils.mkdir_p(DUMP_DIR)

FF_USER_URL = "http://friendfeed.com/api/feed/user/#{USER}"
FF_COMMENTS_URL = "http://friendfeed.com/api/feed/user/#{USER}/comments"
FF_LIKES_URL = "http://friendfeed.com/api/feed/user/#{USER}/likes"
URLS = [FF_USER_URL, FF_COMMENTS_URL, FF_LIKES_URL]

client = HTTPClient.new
# let HTTPClient sends Authorization header without waiting 401 response.
URLS.each do |url|
  client.www_auth.basic_auth.challenge(URI.parse(url), true)
end
client.set_auth(nil, USER, REMOTE_KEY)

URLS.each do |url|
  JSON.parse(client.get_content(url))['entries'].each do |entry|
    published = entry['published']
    id = entry['id']
    filename = File.join(DUMP_DIR, "#{published}_#{id}.xml")
    File.open(filename, 'w') do |f|
      f.write(XSD::Mapping.obj2xml(entry, 'entry'))
    end
  end
end
