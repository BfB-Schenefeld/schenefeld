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
    dow_element = row.at_css('.dow')
    dom_element = row.at_css('.dom')
    time_element = row.at_css('.time div')
    title_element = row.at_css('.textCol a')
    room_element = row.at_css('.raum div')

    if dow_element && dom_element && time_element && title_element && room_element
      dow = dow_element.text.strip
      dom = dom_element.text.strip
      time = time_element.text.strip
      title = title_element.text.strip
      url = "https://www.sitzungsdienst-schenefeld.de/bi/#{title_element['href']}"
      room = room_element.text.strip
      formatted_date = extract_and_format_date(dow, dom, month, year)

      puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{url}, Raum: #{room}"
      scrape_event_details(url)
    end
  end
end

def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))

  document.css('tr').each do |row|
    index_number = row.at_css('td.tonr a').text.strip rescue ''
    betreff = row.at_css('td.tobetreff div a').text.strip rescue row.at_css('td.tobetreff div').text.strip
    top_url = row.at_css('td.tobetreff div a')['href'] rescue nil
    top_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{top_url}" if top_url
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"

    if !index_number.empty? && !betreff.empty?
      puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
      scrape_top_details(top_url) if top_url
      scrape_vorlagen_details(vorlage_url) if vorlage_url != "-"
    end
  end
end

def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))
  
  top_protokolltext_element = document.at_css('#mainContent')
  top_protokolltext = top_protokolltext_element ? top_protokolltext_element.text.gsub(/\s+/, ' ').strip : "Kein TOP-Protokolltext gefunden"
  puts "TOP-Protokolltext: #{top_protokolltext}"

  vorlagen_betreff_element = document.at_css('span#vobetreff a')
  if vorlagen_betreff_element
    vorlagen_betreff = vorlagen_betreff_element.text.strip
    vorlagen_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}"
    puts "Vorlagen-Betreff: #{vorlagen_betreff}, Vorlagen-URL: #{vorlagen_url}"
    scrape_vorlagen_details(vorlagen_url)
  else
    puts "Keine Vorlage vorhanden."
  end
end

def scrape_vorlagen_details(vorlagen_url)
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  document = Nokogiri::HTML(open(vorlagen_url))

  vorlagenbezeichnung_element = document.at_css('#header h1.title')
  vorlagenbezeichnung = vorlagenbezeichnung_element ? vorlagenbezeichnung_element.text.strip : "Keine Vorlagenbezeichnung gefunden"
  puts "Vorlagenbezeichnung: #{vorlagenbezeichnung}"

  vorlagenprotokolltext_element = document.at_css('#mainContent')
  vorlagenprotokolltext = vorlagenprotokolltext_element ? vorlagenprotokolltext_element.text.gsub(/\s+/, ' ').strip : "Kein Text im Hauptinhalt gefunden"
  puts "Vorlagenprotokolltext: #{vorlagenprotokolltext}"

  vorlagen_pdf_link = document.at_css('a.doclink.pdf')
  vorlagen_pdf_url = vorlagen_pdf_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_pdf_link['href']}" : "Keine Vorlagen-PDF-URL gefunden"
  puts "Vorlagen-PDF-URL: #{vorlagen_pdf_url}"

  sammel_pdf_link = document.xpath("//a[contains(@data-simpletooltip-text, 'Vorlage-Sammeldokument')]").first
  sammel_pdf_url = sammel_pdf_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{sammel_pdf_link['href']}" : "Keine Vorlagen-Sammel-PDF-URL gefunden"
  puts "Vorlagen-Sammel-PDF-URL: #{sammel_pdf_url}"
end

# Start the scraping process for a given month and year
scrape_calendar_data('2024', '3')

































