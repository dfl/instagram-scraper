require_relative './instagram'

if username = ARGV[0]
  user_id = Float(username) rescue false
  user_id ||= get_user_id(username)
  scrape_user_posts(user_id, page_size: 12)
else
  puts "Usage: ruby #{__FILE__} USERNAME >> urls.txt"
  exit
end
