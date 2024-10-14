require 'json'
require 'open-uri'
require 'net/http'
require 'nokogiri'
require 'ferrum'

QUERY_HASHES = {
  user_posts: "e769aa130647d2354c40ea6a439bfc08",
  user_info: "c9100bf9110dd6361671f113dd02e7d6",
  post_comments: "bc3296d1ce80a24b1b6e40b1e72903f5"
}

HEADERS = {
  # this is internal ID of an instegram backend app. It doesn't change often.
  "x-ig-app-id": "936619743392459",
  # use browser-like features
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
  # https://www.zenrows.com/blog/user-agent-web-scraping#best
  "Accept-Language": "en-US,en;q=0.9,ru;q=0.8",
  "Accept-Encoding": "gzip, deflate, br",
  "Accept": "*/*",
}

def get_user_id(username)
  url = "https://i.instagram.com/api/v1/users/web_profile_info/?username=#{username}"
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    request = Net::HTTP::Get.new(uri)
    HEADERS.each { |key, value| request[key] = value }
    http.request(request)
  end

  data = JSON.parse(response.body)["data"]

  data["user"]["id"]
end

def scrape_user_posts(user_id, page_size: 12, max_pages: nil, start_page: 1)
  browser = Ferrum::Browser.new(headless: true)
  browser.headers.set({"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 OPR/109.0.0.0"})

  base_url = "https://www.instagram.com/graphql/query/?query_hash=#{QUERY_HASHES[:user_posts]}&variables="

  variables = {
    "id" => user_id,
    "first" => page_size,
    "after" => nil
  }

  page_number = start_page

  loop do
    url = base_url + URI.encode_www_form_component(JSON.generate(variables))
    browser.go_to(url)

    # Wait for the content to load
    browser.network.wait_for_idle

    # Extract the JSON from the page
    response = browser.body
    json_content = Nokogiri.parse(response).css("pre").text
    data = JSON.parse(json_content)

    posts = data["data"]["user"]["edge_owner_to_timeline_media"]
    posts["edges"].each do |post|
      parse_post(post["node"])
    end

    page_info = posts["page_info"]

    # if page_number == 1
    #   puts "** Scraping total #{posts['count']} posts from User #{user_id}"
    # else
    #   puts "** Scraping page #{page_number}"
    # end

    break unless page_info["has_next_page"]
    break if variables["after"] == page_info["end_cursor"]

    variables["after"] = page_info["end_cursor"]
    page_number += 1

    break if max_pages && page_number > max_pages
  end

  browser.quit
end


def parse_post(node)
  post = {
    id: node["id"],
    shortcode: node["shortcode"],
    display_url: node["display_url"],
    likes: node["edge_media_preview_like"]["count"],
    comments: node["edge_media_to_comment"]["count"],
    caption: node.dig("edge_media_to_caption", "edges", 0, "node", "text"),
    timestamp: node["taken_at_timestamp"]
  }

  # file = File.join("output", "#{post[:timestamp]}.jpg")
  # File.write(file, URI.open(post[:display_url]).read) unless File.exist?(file)

  puts post[:display_url]
  # puts post[:caption]
  post
end
