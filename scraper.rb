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

# Funktion zum Scrapen von Details einer Sitzungswebseite
def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))

  event_data = []
  document.css('tr').each do |row|
    index_number = row.css('td.tonr a').text.strip rescue ''
    betreff = row.css('td.tobetreff div a').text.strip rescue row.css('td.tobetreff div').text.strip
    top_link = row.at_css('td.tobetreff div a')
    top_url = top_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{top_link['href']}" : "-"
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"

    if !index_number.empty? && !betreff.empty?
      event_data << [index_number, betreff, top_url, vorlage_text, vorlage_url]
      puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
    end
  end
  return event_data
end

# Beispiel-URL (bitte durch eine gültige URL ersetzen)
test_url = 'https://www.sitzungsdienst-schenefeld.de/bi/to010_r.asp?SILFDNR=4967'
scrape_event_details(test_url)









