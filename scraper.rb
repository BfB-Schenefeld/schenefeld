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
