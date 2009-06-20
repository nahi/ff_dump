#!/usr/local/bin/ruby

require 'httpclient'
require 'json'
require 'xsd/mapping'
require 'fileutils'

def usage
  "#{$0} nickname remote_api_key dump_dir"
end

module JSONFilter
  class << self
    def parse(str)
      safe = filter_utf8(str)
      JSON.parse(safe)
    end

    def pretty_generate(obj)
      JSON.pretty_generate(obj)
    end

  private

    # these definition source code is from soap4r.
    us_ascii = '[\x9\xa\xd\x20-\x7F]'     # XML 1.0 restricted.
    # 0xxxxxxx
    # 110yyyyy 10xxxxxx
    twobytes_utf8 = '(?:[\xC0-\xDF][\x80-\xBF])'
    # 1110zzzz 10yyyyyy 10xxxxxx
    threebytes_utf8 = '(?:[\xE0-\xEF][\x80-\xBF][\x80-\xBF])'
    # 11110uuu 10uuuzzz 10yyyyyy 10xxxxxx
    fourbytes_utf8 = '(?:[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF])'
    CHAR_UTF_8 = "(?:#{us_ascii}|#{twobytes_utf8}|#{threebytes_utf8}|#{fourbytes_utf8})"

    def filter_utf8(str)
      str.scan(/(#{CHAR_UTF_8})|(.)/n).collect { |u, x|
        if u
          u
        else
          sprintf("\\x%02X", x[0])
        end
      }.join
    end
  end
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
  JSONFilter.parse(client.get_content(url))['entries'].each do |entry|
    published = entry['published']
    id = entry['id']
    filename = File.join(DUMP_DIR, "#{published}_#{id}.xml")
    File.open(filename, 'w') do |f|
      f.write(XSD::Mapping.obj2xml(entry, 'entry'))
    end
  end
end
