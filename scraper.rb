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

# Extrahiert Details von jeder Veranstaltungsseite
def scrape_event_details(event_url)
  begin
    document = Nokogiri::HTML(open(event_url))
    event_title = document.at_css('a[href*="to010_r.asp?SILFDNR="]').text.strip
    time = document.at_css('td.time div').text.strip
    room = document.at_css('td.raum div').text.strip
    puts "#{Date.parse(event_url[/DD=(\d+)/, 1] + '.' + event_url[/MM=(\d+)/, 1] + '.' + event_url[/YY=(\d+)/, 1]).strftime('%a. %d.%m.%Y')} um #{time}: #{event_title}, Raum: #{room}, URL: #{event_url}"

    document.css('tr').each do |row|
      index_number = row.css('td.tonr a').text.strip
      betreff = row.css('td.tobetreff div a').text.strip
      vorlage_link = row.at_css('td.tovonr a')
      vorlage_text = vorlage_link ? vorlage_link.text.strip : "keine Vorlage"
      vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : ""

      detail_output = "#{index_number}: #{betreff}"
      detail_output += ", Vorlage #{vorlage_text}" unless vorlage_text == "keine Vorlage"
      detail_output += ", Vorlagen-URL: #{vorlage_url}" unless vorlage_url.empty?
      
      puts detail_output
    end
  rescue StandardError => e
    puts "Fehler beim Extrahieren von Details der Veranstaltungsseite: #{e.message}"
  end
end

# Iteriert über Kalenderdaten und ruft Event-Details ab
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  begin
    document = Nokogiri::HTML(open(url))
    event_links = document.css('a[href*="to010_r.asp?SILFDNR="]').map { |link| "https://www.sitzungsdienst-schenefeld.de/bi/#{link['href']}" }
    
    puts "Sitzungen für #{Date::MONTHNAMES[month]} #{year}"
    event_links.each { |link| scrape_event_details(link) }
  rescue StandardError => e
    puts "Fehler beim Extrahieren der Kalenderdaten: #{e.message}"
  end
end

# Startet das Scraping für einen bestimmten Monat und Jahr
scrape_calendar_data(2024, 3)

