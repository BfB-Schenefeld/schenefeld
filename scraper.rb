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
  base_url = "https://www.sitzungsdienst-schenefeld.de/bi/"

  # Extraktion der Vorlagen-Betreffs, wenn vorhanden
  vorlagen_betreff_element = document.at_css('span#vobetreff a')
  vorlagen_betreff_text, vorlagen_url = if vorlagen_betreff_element
    [vorlagen_betreff_element.text.strip, base_url + vorlagen_betreff_element['href']]
  else
    ["-", "-"]
  end
  puts "Vorlagen-Betreff: #{vorlagen_betreff_text}, Vorlagen-URL: #{vorlagen_url}"

  # Extraktion des TOP-Sammel-PDFs, wenn vorhanden
  sammel_pdf_link = document.at_css('a.doclink.pdf')
  sammel_pdf_url = sammel_pdf_link ? base_url + sammel_pdf_link['href'] : "-"
  puts "Sammel-PDF URL: #{sammel_pdf_url}"

  # Extraktion von Anlagen-PDFs, wenn vorhanden
  anlagen_pdf_links = document.css('a.attlink.pdf').map do |link|
    base_url + link['href']
  end
  puts "Anlagen-PDF URLs: #{anlagen_pdf_links.join(', ')}"

  [vorlagen_betreff_text, vorlagen_url, sammel_pdf_url, anlagen_pdf_links]
end

# Beispiel-URL für eine TOP-Seite
test_top_url = 'https://www.sitzungsdienst-schenefeld.de/bi/to020_r.asp?TOLFDNR=23716'
scrape_top_details(test_top_url)












