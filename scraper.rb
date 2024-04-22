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

# Ebene 1: Kalenderdaten scrapen
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))
  
  document.css('tr:not(.emptyRow)').each do |row|
    title_element = row.at_css('.textCol a')
    if title_element
      event_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{title_element['href']}"
      scrape_event_details(event_url) # Ebene 2 aufrufen
    end
  end
end

# Ebene 2: Details einer Sitzungswebseite scrapen
def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))
  
  document.css('tr').each do |row|
    top_link = row.at_css('td.tobetreff div a')
    if top_link
      top_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{top_link['href']}"
      scrape_top_details(top_url) # Ebene 3 aufrufen
    end
  end
end

# Ebene 3: Details einer TOP-Seite scrapen
def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))

  vorlagen_link = document.at_css('span#vobetreff a')
  if vorlagen_link
    vorlagen_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_link['href']}"
    scrape_vorlagen_details(vorlagen_url) # Ebene 4 aufrufen
  end
end

# Ebene 4: Details einer Vorlagenseite scrapen
def scrape_vorlagen_details(vorlagen_url)
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  document = Nokogiri::HTML(open(vorlagen_url))

  # Extrahieren der Vorlagenbezeichnung
  vorlagenbezeichnung_element = document.at_css('#header h1.title')
  vorlagenbezeichnung = vorlagenbezeichnung_element ? vorlagenbezeichnung_element.text.strip : "Keine Vorlagenbezeichnung gefunden"
  puts "Vorlagenbezeichnung: #{vorlagenbezeichnung}"

  # Extrahieren des gesamten Texts von mainContent
  vorlagenprotokolltext_element = document.at_css('#mainContent')
  vorlagenprotokolltext = vorlagenprotokolltext_element ? vorlagenprotokolltext_element.text.gsub(/\s+/, ' ').strip : "Kein Text im Hauptinhalt gefunden"
  puts "Vorlagenprotokolltext: #{vorlagenprotokolltext}"

  # Extrahieren der Vorlagen-PDF-URL
  vorlagen_pdf_link = document.at_css('a.doclink.pdf')
  vorlagen_pdf_url = vorlagen_pdf_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_pdf_link['href']}" : "Keine Vorlagen-PDF-URL gefunden"
  puts "Vorlagen-PDF-URL: #{vorlagen_pdf_url}"

  # Extrahieren der Vorlagen-Sammel-PDF-URL
  sammel_pdf_link = document.xpath("//a[contains(@data-simpletooltip-text, 'Vorlage-Sammeldokument')]").first
  sammel_pdf_url = sammel_pdf_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{sammel_pdf_link['href']}" : "Keine Vorlagen-Sammel-PDF-URL gefunden"
  puts "Vorlagen-Sammel-PDF-URL: #{sammel_pdf_url}"
end


# Starte den Prozess
scrape_calendar_data('2024', '3')





























