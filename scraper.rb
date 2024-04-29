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
  # ... (keep the existing method implementation)
end

def scrape_vorlagen_details(vorlagen_url)
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  document = Nokogiri::HTML(open(vorlagen_url))

  # ... (keep the existing method implementation)

  # Return the extracted data as a hash
  {
    vorlagenbezeichnung: vorlagenbezeichnung,
    vorlagenprotokolltext: vorlagenprotokolltext,
    vorlagen_pdf_url: vorlagen_pdf_url,
    sammel_pdf_url: sammel_pdf_url
  }
end

def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  document = Nokogiri::HTML(open(top_url))

  # ... (keep the existing method implementation)

  # Extract Vorlagen details if available
  vorlagen_data = nil
  if vorlagen_betreff_element
    vorlagen_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}"
    vorlagen_data = scrape_vorlagen_details(vorlagen_url)
  end

  # Return the extracted data as a hash
  {
    top_protokolltext: top_protokolltext,
    vorlagen_data: vorlagen_data
  }
end

def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  document = Nokogiri::HTML(open(event_url))

  event_data = []
  document.css('tr').each do |row|
    index_number_element = row.at_css('td.tonr a')
    index_number = index_number_element ? index_number_element.text.strip : ''

    betreff_element = row.at_css('td.tobetreff div a') || row.at_css('td.tobetreff div')
    betreff = betreff_element ? betreff_element.text.strip : ''

    top_link = row.at_css('td.tobetreff div a')
    top_url = top_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{top_link['href']}" : "-"

    vorlage_link = row.at_css('td.tovonr a')
    vorlage_text = vorlage_link ? vorlage_link.text.strip : "-"
    vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : "-"

    if !index_number.empty? && !betreff.empty?
      # Scrape TOP details
      top_data = scrape_top_details(top_url)

      event_data << {
        index_number: index_number,
        betreff: betreff,
        top_url: top_url,
        vorlage_text: vorlage_text,
        vorlage_url: vorlage_url,
        top_data: top_data
      }
      puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
    end
  end
  event_data
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  document = Nokogiri::HTML(open(url))

  calendar_data = []
  document.css('tr:not(.emptyRow)').each do |row|
    dow_element = row.at_css('.dow')
    dom_element = row.at_css('.dom')
    time_element = row.at_css('.time div')
    title_element = row.at_css('.textCol a')
    room_element = row.at_css('.raum div')

    if dow_element && dom_element && time_element && title_element && room_element
      dow = dow_element.text
      dom = dom_element.text
      time = time_element.text
      title = title_element.text
      url = "https://www.sitzungsdienst-schenefeld.de/bi/#{title_element['href']}"
      room = room_element.text
      formatted_date = extract_and_format_date(dow, dom, month, year)

      # Scrape event details
      event_data = scrape_event_details(url)

      calendar_data << {
        date: formatted_date,
        time: time,
        title: title,
        url: url,
        room: room,
        event_data: event_data
      }
      puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{url}, Raum: #{room}"
    end
  end
  calendar_data
end
# Example usage
year = '2024'
month = '3'
calendar_data = scrape_calendar_data(year, month)

# Print the scraped data
puts calendar_data
