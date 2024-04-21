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
require 'open-uri'
require 'nokogiri'
require 'date'

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  begin
    document = Nokogiri::HTML(open(url))
    document.css('a[href*="si010_r.asp?DD="]').each do |link|
      day = link['href'][/DD=(\d+)/, 1]
      month = link['href'][/MM=(\d+)/, 1]
      year = link['href'][/YY=(\d+)/, 1]
      formatted_date = "#{day}.#{month}.#{year}"
      puts "Datum: #{formatted_date}, URL: #{link['href']}"
    end
  rescue StandardError => e
    puts "Error during calendar data scrape: #{e.message}"
  end
end

# Test the function with a specific month and year
scrape_calendar_data(2024, 3)
