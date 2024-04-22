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

# Funktion, um Details von der Ebene-4-Seite (Vorlagenseite) zu scrapen
def scrape_vorlagen_details(vorlagen_url)
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  document = Nokogiri::HTML(open(vorlagen_url))

  # Extrahieren der Vorlagenbezeichnung
  vorlagenbezeichnung_element = document.at_css('#header h1.title')
  vorlagenbezeichnung = vorlagenbezeichnung_element ? vorlagenbezeichnung_element.text.strip : "Keine Vorlagenbezeichnung gefunden"
  puts "Vorlagenbezeichnung: #{vorlagenbezeichnung}"

  # Extrahieren und Bereinigen des gesamten Texts von mainContent
  vorlagenprotokolltext_element = document.at_css('#mainContent')
  if vorlagenprotokolltext_element
    vorlagenprotokolltext = vorlagenprotokolltext_element.text
    vorlagenprotokolltext = vorlagenprotokolltext.gsub(/\s+/, ' ').strip # Ersetzt mehrfache Leerzeichen durch ein einzelnes und entfernt führende/anhängende Leerzeichen
    vorlagenprotokolltext = vorlagenprotokolltext.gsub(/(?:\r?\n|\r)+/, ' ') # Ersetzt neue Zeilen durch ein Leerzeichen, um Text kompakter zu machen
  else
    vorlagenprotokolltext = "Kein Text im Hauptinhalt gefunden"
  end
  puts "Vorlagenprotokolltext: #{vorlagenprotokolltext}"
end

# Beispiel-URL für die Funktion
vorlagen_url = 'https://www.sitzungsdienst-schenefeld.de/bi/vo020_r.asp?VOLFDNR=4926'
scrape_vorlagen_details(vorlagen_url)



















