require 'open-uri'

if urls = ARGV[0]
  File.open(urls, "r").each do |url|
    filename = url.split("/").last.split('?').first
    file = File.join("output", filename)
    if File.exist?(file)
      puts "[EXISTS] #{file}"
    else
      uri = URI.open(url)
      puts "[FETCH] #{file}"
      # p url
      # p uri.meta
      # p filename = uri.meta['content-disposition'].match(/filename=(\"?)(.+)\1/)[2]
      File.write(file, uri.read)
    end
  end
else
  puts "Usage: ruby #{__FILE__} urls.txt"
  exit
end
