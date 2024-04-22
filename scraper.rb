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

# Methode zur Extraktion und Formatierung des Datums
def extract_and_format_date(dow, dom, month, year)
  # Erstellen eines Datumsstrings im deutschen Format "Tag, DD.MM.YYYY"
  formatted_date = "#{dow}, #{dom.rjust(2, '0')}.#{month.rjust(2, '0')}.#{year}"
  begin
    # Parsen des Datums im deutschen Format und Konvertieren in ein Datum-Objekt
    date = Date.strptime(formatted_date, "%a, %d.%m.%Y")
    # Rückgabe des formatierten Datums
    date.strftime("%a., %d.%m.%Y") # Z.B. "Di., 05.03.2024"
  rescue ArgumentError
    'Invalid date'
  end
end

# Methode zum Scrapen der Kalenderdaten (Ebene 1)
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))

  # Extraktion der Sitzungsdaten aus der Kalendertabelle
  document.css('tr:not(.emptyRow)').each do |row|
    dow = row.at_css('.dow').text
    dom = row.at_css('.dom').text.rjust(2, '0')
    time = row.at_css('.time div').text
    title = row.at_css('.textCol a').text
    url = "https://www.sitzungsdienst-schenefeld.de/bi/#{row.at_css('.textCol a')['href']}"
    room = row.at_css('.raum div').text
    formatted_date = extract_and_format_date(dow, dom, month, year)

    puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{url}, Raum: #{room}"
  end
end

# Testaufruf für März 2024
scrape_calendar_data('2024', '3')



