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

def extract_and_format_date(dow, dom, month, year)
  dom = dom.to_s.rjust(2, '0')
  month = month.to_s.rjust(2, '0')
  dow_translation = {'Mo' => 'Mon', 'Di' => 'Tue', 'Mi' => 'Wed', 'Do' => 'Thu', 'Fr' => 'Fri', 'Sa' => 'Sat', 'So' => 'Sun'}
  dow_en = dow_translation[dow]
  date_str = "#{dow_en}, #{dom} #{Date::MONTHNAMES[month.to_i]} #{year}"
  begin
    date = Date.parse(date_str)
    german_days = { 'Mon' => 'Mo.', 'Tue' => 'Di.', 'Wed' => 'Mi.', 'Thu' => 'Do.', 'Fri' => 'Fr.', 'Sat' => 'Sa.', 'Sun' => 'So.' }
    "#{german_days[date.strftime('%a')]} #{date.strftime('%d.%m.%Y')}"
  rescue ArgumentError
    'Invalid date'
  end
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))

  document.css('tr:not(.emptyRow)').each do |row|
    dow = row.at_css('.dow')&.text&.strip
    dom = row.at_css('.dom')&.text&.strip
    time = row.at_css('.time div')&.text&.strip
    title_element = row.at_css('.textCol a')
    room = row.at_css('.raum div')&.text&.strip

    next unless dow && dom && time && title_element && room

    formatted_date = extract_and_format_date(dow, dom, month, year)
    puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title_element.text.strip}, URL: #{'https://www.sitzungsdienst-schenefeld.de/bi/' + title_element['href']}, Raum: #{room}"
    scrape_event_details('https://www.sitzungsdienst-schenefeld.de/bi/' + title_element['href'])
  end
end

def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))

  document.css('tr').each do |row|
    index_number = row.at_css('td.tonr a')&.text&.strip
    betreff = row.at_css('td.tobetreff div a')&.text&.strip || row.at_css('td.tobetreff div')&.text&.strip
    top_url = row.at_css('td.tobetreff div a')&['href']
    top_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{top_url}" if top_url
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link&.text&.strip || "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"

    next unless index_number && betreff

    puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
    scrape_top_details(top_url) if top_url
    scrape_vorlagen_details(vorlage_url) if vorlage_url != "-"
  end
end

def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))
  
  top_protokolltext_element = document.at_css('#mainContent')
  top_protokolltext = top_protokolltext_element ? top_protokolltext_element.text.gsub(/\s+/, ' ').strip : "Kein TOP-Protokolltext gefunden"
  puts "TOP-Protokolltext: #{top_protokolltext}"

  vorlagen_betreff_element = document.at_css('span#vobetreff a')
  vorlagen_url = vorlagen_betreff_element ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}" : nil
  puts "Vorlagen-Betreff gefunden: #{vorlagen_betreff_element&.text&.strip}, Vorlagen-URL: #{vorlagen_url}"
  scrape_vorlagen_details(vorlagen_url) if vorlagen_url
end

def scrape_vorlagen_details(vorlagen_url)
  return unless vorlagen_url
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  document = Nokogiri::HTML(open(vorlagen_url))

  vorlagenbezeichnung = document.at_css('#header h1.title')&.text&.strip || "Keine Vorlagenbezeichnung gefunden"
  vorlagenprotokolltext = document.at_css('#mainContent')&.text&.gsub(/\s+/, ' ')&.strip || "Kein Vorlagenprotokolltext gefunden"
  puts "Vorlagenbezeichnung: #{vorlagenbezeichnung}"
  puts "Vorlagenprotokolltext: #{vorlagenprotokolltext}"

  vorlagen_pdf_url = document.at_css('a.doclink.pdf')&['href']
  vorlagen_pdf_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_pdf_url}" if vorlagen_pdf_url
  puts "Vorlagen-PDF-URL: #{vorlagen_pdf_url}"
end

# Startpunkt
scrape_calendar_data('2024', '3')































