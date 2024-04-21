# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find something on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
require 'nokogiri'
require 'open-uri'

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  document = Nokogiri::HTML(open(url))

  document.css('tr').each do |row|
    date_raw = row.at_css('td:nth-child(1)').text.strip rescue nil
    time = row.at_css('td:nth-child(2)').text.strip rescue nil
    meeting = row.at_css('td:nth-child(3)').text.strip rescue nil
    location = row.at_css('td:nth-child(4)').text.strip rescue nil
    link = row.at_css('td:nth-child(3) a')['href'] rescue nil
    link_full_url = link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{link}" : nil

    if date_raw && time && meeting && location
      # Adjust date to include leading zero
      date_parts = date_raw.scan(/\D*(\d+)$/).flatten.first
      date = date_parts ? date_raw.sub(/\d+$/, date_parts.rjust(2, '0')) : date_raw

      puts "Date: #{date}, Time: #{time}, Meeting: #{meeting}, Location: #{location}, URL: #{link_full_url}"
    end
  end
end

# Example: Scrape data for April 2024
scrape_calendar_data(2024, 4)


