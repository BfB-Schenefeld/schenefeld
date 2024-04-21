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
require 'nokogiri'
require 'open-uri'

def scrape_details(url)
  begin
    full_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{url}"
    document = Nokogiri::HTML(open(full_url))

    document.css('tbody tr').each do |row|
      top_link = row.css('td.tonr a').first
      top_id = top_link['href'][/TOLFDNR=(\d+)/, 1]
      top_description = row.css('td.tobetreff div a').text.strip

      top_url = "https://www.sitzungsdienst-schenefeld.de/bi/to020_r.asp?TOLFDNR=#{top_id}"

      vo_link = row.css('td.tovonr a').first
      vo_id = vo_link ? vo_link['href'][/VOLFDNR=(\d+)/, 1] : nil
      vo_url = vo_link ? "https://www.sitzungsdienst-schenefeld.de/bi/vo020_r.asp?VOLFDNR=#{vo_id}" : "-"

      puts "  Tagesordnungspunkt: #{top_link.text.strip} #{top_description}, URL: #{top_url}, Beschlussvorlage: #{vo_url}"
    end
  rescue => e
    puts "Failed to scrape details: #{e.message}"
  end
end

def scrape_calendar_data(year, month)
  begin
    url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
    document = Nokogiri::HTML(open(url))

    document.css('a[href*="si010_r.asp?DD="]').each do |link|
      day = link['href'][/DD=(\d+)/, 1]
      month = link['href'][/MM=(\d+)/, 1]
      year = link['href'][/YY=(\d+)/, 1]
      formatted_date = "#{day}.#{month}.#{year}"
      puts "Datum: #{formatted_date}, URL: #{link['href']}"
      scrape_details(link['href'])
    end
  rescue => e
    puts "Failed to scrape calendar data: #{e.message}"
  end
end

# Example: Data scraping for March 2024
scrape_calendar_data(2024, 3)

