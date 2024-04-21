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
  document = Nokogiri::HTML(open(event_url))

  # Assuming the date is in a specific format or contained in a specific element
  # This part needs to be adjusted based on actual HTML structure of the event page
  date_text = document.at_css('specific_selector_for_date').text.strip
  puts "Date found on event page: #{date_text}"
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Attempting to access URL: #{url}"
  begin
    document = Nokogiri::HTML(open(url))
    puts "Calendar page loaded successfully."

    event_links = document.css('a[href*="to010_r.asp?SILFDNR="]').map { |link| "https://www.sitzungsdienst-schenefeld.de/bi/#{link['href']}" }
    puts "Number of event links found: #{event_links.count}"

    event_links.each do |link|
      scrape_event_details(link)
    end
  rescue StandardError => e
    puts "Error during calendar data scrape: #{e.message}"
  end
end

scrape_calendar_data(2024, 3)
