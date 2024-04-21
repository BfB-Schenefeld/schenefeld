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
  puts "Accessing event page: #{event_url}"
  document = Nokogiri::HTML(open(event_url))
  
  event_data = []
  document.css('tr').each do |row|
    index_number = row.css('td.tonr a').text.strip
    betreff_link = row.css('td.tobetreff div a').first
    betreff_text = if betreff_link
                     betreff_link.text.strip
                   else
                     row.css('td.tobetreff div').text.strip
                   end
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : nil

    # Speichere Daten nur, wenn 'index_number' und 'betreff_text' nicht leer sind
    if !index_number.empty? && !betreff_text.empty?
      data_entry = [index_number, betreff_text, vorlage_text]
      data_entry << vorlage_url if vorlage_url  # Füge die Vorlagen-URL nur hinzu, wenn sie vorhanden ist
      event_data << data_entry
      output_text = "Found: #{index_number}, Betreff: #{betreff_text}, Vorlage: #{vorlage_text}"
      output_text += ", Vorlage URL: #{vorlage_url}" if vorlage_url
      puts output_text
    end
  end
  return event_data
end

# Function to iterate over calendar data and fetch event details
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Attempting to access URL: #{url}"
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
    headers = ["Index Number", "Betreff", "Vorlage Text"]
    headers << "Vorlage URL" if data.any? { |row| row.length > 3 }  # Füge die URL-Spalte hinzu, wenn URLs vorhanden sind
    csv << headers
    data.each { |row| csv << row }
  end
end

# Start scraping
scrape_calendar_data(2024, 3)

