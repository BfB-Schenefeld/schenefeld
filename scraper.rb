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

# Funktion zum Scrapen von Details einer TOP-Seite (Ebene 3)
def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))
  
  # Extraktion des Vorlagen-Betreffs, wenn vorhanden
  vorlagen_betreff_element = document.at_css('span#vobetreff a')
  if vorlagen_betreff_element
    vorlagen_betreff_text = vorlagen_betreff_element.text.strip
    vorlagen_betreff_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}"
    puts "Vorlagen-Betreff gefunden: #{vorlagen_betreff_text}, URL: #{vorlagen_betreff_url}"
    [vorlagen_betreff_text, vorlagen_betreff_url]
  else
    puts "Kein Vorlagen-Betreff vorhanden."
    ["-", "-"]
  end
end

# Beispiel-URL für eine TOP-Seite
test_top_url = 'https://www.sitzungsdienst-schenefeld.de/bi/to020_r.asp?TOLFDNR=23884'
scrape_top_details(test_top_url)










