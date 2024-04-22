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
require 'date'

# Funktion zum Formatieren des Datums
def format_date(day, month, year)
  # Führende Nullen hinzufügen, falls nötig
  day = day.rjust(2, '0')
  month = month.rjust(2, '0')
  
  date_string = "#{day}.#{month}.#{year}"
  date = Date.parse(date_string)
  # Wochentag abkürzen (z.B. "Di" für Dienstag) und Datum formatieren
  date.strftime("%a., %d.%m.%Y") # Z.B. "Di., 05.03.2024"
rescue ArgumentError
  nil # Bei ungültigem Datum wird nil zurückgegeben
end

# Scrape Kalender-Daten inklusive aller Sitzungen (Ebene 1)
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))
  
  all_event_data = []
  document.css('tr:not(.emptyRow)').each do |row|
    day = row.css('.dom').text.strip
    formatted_date = format_date(day, month, year)
    time = row.css('.time div').text.strip
    sitzung_title = row.css('.textCol a').text.strip
    sitzung_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{row.css('.textCol a')[0]['href']}"
    raum = row.css('.raum div').text.strip
    
    # Daten speichern, wenn sinnvoller Inhalt vorhanden ist
    if !sitzung_title.empty?
      event_data = {
        date: formatted_date,
        time: time,
        title: sitzung_title,
        url: sitzung_url,
        room: raum
      }
      all_event_data << event_data
      puts "Sitzung geplant am: #{formatted_date}, um: #{time}, Titel: #{sitzung_title}, Raum: #{raum}, URL: #{sitzung_url}"
    end
  end

  save_to_csv(all_event_data)
end

# Daten in CSV speichern (Daten speichern)
def save_to_csv(data)
  CSV.open("event_details.csv", "wb") do |csv|
    csv << ["Datum", "Uhrzeit", "Titel", "URL", "Raum"]
    data.each { |row| csv << [row[:date], row[:time], row[:title], row[:url], row[:room]] }
  end
end

# Start des Scrapings (Scraping starten)
scrape_calendar_data(2024, 3)

