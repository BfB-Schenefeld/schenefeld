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
  dom = dom.to_s.rjust(2, '0')
  month = month.to_s.rjust(2, '0')
  dow_translation = {
    'Mo' => 'Mon', 'Di' => 'Tue', 'Mi' => 'Wed',
    'Do' => 'Thu', 'Fr' => 'Fri', 'Sa' => 'Sat', 'So' => 'Sun'
  }
  dow_en = dow_translation[dow]
  date_str = "#{dow_en}, #{dom} #{Date::MONTHNAMES[month.to_i]} #{year}"
  begin
    date = Date.parse(date_str)
    german_days = {'Mon' => 'Mo.', 'Tue' => 'Di.', 'Wed' => 'Mi.', 'Thu' => 'Do.', 'Fri' => 'Fr.', 'Sat' => 'Sa.', 'Sun' => 'So.'}
    "#{german_days[date.strftime('%a')]} #{date.strftime('%d.%m.%Y')}"
  rescue ArgumentError
    'Invalid date'
  end
end

# Methode zum Scrapen der Kalenderdaten (Ebene 1)
def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))

  document.css('tr:not(.emptyRow)').each do |row|
    dow = row.at_css('.dow').text.strip
    dom = row.at_css('.dom').text.strip
    time = row.at_css('.time div').text.strip
    title = row.at_css('.textCol a').text.strip
    event_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{row.at_css('.textCol a')['href']}"
    room = row.at_css('.raum div').text.strip
    formatted_date = extract_and_format_date(dow, dom, month, year)

    puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{event_url}, Raum: #{room}"
    scrape_event_details(event_url) # Aufruf von Ebene 2
  end
end

# Funktion zum Scrapen von Details einer Sitzungswebseite (Ebene 2)
def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))

  document.css('tr').each do |row|
    index_number = row.css('td.tonr a').text.strip rescue ''
    betreff = row.css('td.tobetreff div a').text.strip rescue row.css('td.tobetreff div').text.strip
    top_url = row.at_css('td.tobetreff div a') ? "https://www.sitzungsdienst-schenefeld.de/bi/#{row.at_css('td.tobetreff div a')['href']}" : "-"
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"

    if !index_number.empty? && !betreff.empty?
      puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
      scrape_top_details(top_url) if top_url != "-"
      scrape_vorlagen_details(vorlage_url) if vorlage_url != "-"
    end
  end
end

# Funktion zum Scrapen von Details einer TOP-Seite (Ebene 3)
def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))
  main_content = document.at_css('#mainContent').text.gsub(/\s+/, ' ').strip
  puts "TOP-Protokolltext: #{main_content}"
end

# Funktion, um Details von der Ebene-4-Seite (Vorlagenseite) zu scrapen
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

# Testaufruf für März 2024
scrape_calendar_data('2024', '3')






























