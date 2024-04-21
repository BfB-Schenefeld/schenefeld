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

def scrape_event_details(event_url)
  puts "Accessing event page: #{event_url}"
  begin
    document = Nokogiri::HTML(open(event_url))
    # Extracting the date using the specific selector
    date_link = document.at_css('span#sidatum a')
    date_text = date_link.text.strip if date_link
    puts "Date found on event page: #{date_text}"
  rescue StandardError => e
    puts "Error extracting details from event page: #{e.message}"
  end
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Attempting to access URL: #{url}"
  begin
    document = Nokogiri::HTML(open(url))
    puts "Calendar page loaded successfully."

    # Extracting links to individual event pages
    event_links = document.css('a[href*="to010_r.asp?SILFDNR="]').map do |link|
      "https://www.sitzungsdienst-schenefeld.de/bi/#{link['href']}"
    end
    puts "Number of event links found: #{event_links.count}"

    # Scraping each event page
    event_links.each do |link|
      scrape_event_details(link)
    end
  rescue StandardError => e
    puts "Error during calendar data scrape: #{e.message}"
  end
end

scrape_calendar_data(2024, 3)

