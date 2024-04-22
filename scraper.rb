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
  date = Date.parse(date_str)
  german_days = { 'Mon' => 'Mo.', 'Tue' => 'Di.', 'Wed' => 'Mi.', 'Thu' => 'Do.', 'Fri' => 'Fr.', 'Sat' => 'Sa.', 'Sun' => 'So.' }
  "#{german_days[date.strftime('%a')]} #{date.strftime('%d.%m.%Y')}"
rescue ArgumentError
  'Invalid date'
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  document = Nokogiri::HTML(open(url))
  document.css('tr:not(.emptyRow)').each do |row|
    dow = row.at_css('.dow')&.text&.strip
    dom = row.at_css('.dom')&.text&.strip
    time = row.at_css('.time div')&.text&.strip
    title_element = row.at_css('.textCol a')
    room = row.at_css('.raum div')&.text&.strip

    if dow && dom && time && title_element && room
      title = title_element.text.strip
      event_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{title_element['href']}"
      formatted_date = extract_and_format_date(dow, dom, month, year)
      puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{event_url}, Raum: #{room}"
      scrape_event_details(event_url)
    end
  end
end

def scrape_event_details(event_url)
  document = Nokogiri::HTML(open(event_url))
  document.css('tr').each do |row|
    index_number = row.at_css('td.tonr a')&.text&.strip rescue ''
    betreff = row.at_css('td.tobetreff div a')&.text&.strip rescue row.at_css('td.tobetreff div')&.text&.strip
    top_link = row.at_css('td.tobetreff div a')
    top_url = top_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{top_link['href']}" : "-"
    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"
    puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
    scrape_top_details(top_url) if top_url != "-"
  end
end

def scrape_top_details(top_url)
  document = Nokogiri::HTML(open(top_url))
  main_content_elements = document.css('#mainContent div.expandedDiv, #mainContent div.expandedTitle')
  top_protokolltext = main_content_elements.map { |element| element.text.strip }.join(" ").gsub(/\s+/, ' ')
  puts "TOP-Protokolltext: #{top_protokolltext}"
  vorlagen_betreff_element = document.at_css('span#vobetreff a')
  if vorlagen_betreff_element
    vorlagen_betreff_text = vorlagen_betreff_element.text.strip
    vorlagen_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}"
    puts "Vorlagen-Betreff gefunden: #{vorlagen_betreff_text}, Vorlagen-URL: #{vorlagen_url}"
  else
    puts "Keine Vorlage vorhanden."
  end
end

scrape_calendar_data(2024, 3)


























