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
require 'csv'

# Function to scrape details from each event page
def scrape_event_details(event_url)
  document = Nokogiri::HTML(open(event_url))
  
  event_data = []
  document.css('tr').each do |row|
    index_number = row.css('td.tonr a').text.strip
    betreff = row.css('td.tobetreff div a').text.strip
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "Keine Vorlage"
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "Keine Vorlage"

    event_data << [index_number, betreff, vorlage_text, vorlage_url]
    # Debug-Ausgaben können hier auskommentiert werden:
    # puts "Found: #{index_number}, Betreff: #{betreff}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
  end
  return event_data
end

# Function to iterate over calendar data and fetch event details
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  document = Nokogiri::HTML(open(url))
  event_links = document.css('a[href*="to010_r.asp?SILFDNR="]').map { |link| "https://www.sitzungsdienst-schenefeld.de/bi/#{link['href']}" }
  
  all_event_data = []
  event_links.each do |link|
    all_event_data += scrape_event_details(link)
  end
  save_to_csv(all_event_data)
end

# Function to save data to CSV
def save_to_csv(data)
  CSV.open("event_details.csv", "wb") do |csv|
    csv << ["Index Number", "Betreff", "Vorlage Text", "Vorlage URL"]
    data.each { |row| csv << row }
  end
end

# Start scraping
scrape_calendar_data(2024, 3)

