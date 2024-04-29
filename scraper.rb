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
  begin
    document = Nokogiri::HTML(open(vorlagen_url))
    # ... (keep the existing method implementation)
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Vorlagenseite: #{vorlagen_url}"
    puts "Fehlermeldung: #{e.message}"
    return nil
  end
  # ... (keep the existing method implementation)
end

def scrape_top_details(top_url)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  begin
    document = Nokogiri::HTML(open(top_url))
    # ... (keep the existing method implementation)
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die TOP-Seite: #{top_url}"
    puts "Fehlermeldung: #{e.message}"
    return { top_protokolltext: nil, vorlagen_data: nil }
  end
  # ... (keep the existing method implementation)
end

def scrape_event_details(event_url)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  begin
    document = Nokogiri::HTML(open(event_url))
    # ... (keep the existing method implementation)
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Sitzungsseite: #{event_url}"
    puts "Fehlermeldung: #{e.message}"
    return []
  end
  # ... (keep the existing method implementation)
end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  begin
    document = Nokogiri::HTML(open(url))
    # ... (keep the existing method implementation)
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Kalenderseite: #{url}"
    puts "Fehlermeldung: #{e.message}"
    return []
  end
  # ... (keep the existing method implementation)
end

# Example usage
year = '2024'
month = '3'
calendar_data = scrape_calendar_data(year, month)

# Print the scraped data
puts calendar_data
