#!/usr/local/bin/ruby

require 'httpclient'
require 'logger'

def usage
  "#{$0} nickname password"
end

USER = ARGV.shift or raise usage
PASSWORD = ARGV.shift or raise usage

FF_LOGIN_URL = 'https://friendfeed.com/account/login'

client = HTTPClient.new
client.debug_dev = Logger.new($0 + '.log')
client.set_cookie_store('cookie.dat')
client.get_content(FF_LOGIN_URL)
cookie = client.cookie_manager.cookies.find { |e| e.name == 'AT' }
raise unless cookie
at = cookie.value
query = {
  'email' => USER,
  'password' => PASSWORD,
  'remember' => 'on',
  'next' => 'http://friendfeed.com/',
  'at' => at
}
client.post(FF_LOGIN_URL, query, {'Referer' => 'https://friendfeed.com/account/login'})
client.save_cookie_store
