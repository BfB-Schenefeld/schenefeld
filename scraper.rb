require 'open-uri'
require 'nokogiri'
require 'date'
require 'scraperwiki'
require 'json'
require 'sqlite3'

def valid_url?(url)
  url =~ /\A#{URI::regexp(['http', 'https'])}\z/
end

def extract_and_format_date(dow, dom, month, year)
  dom = dom.to_s.rjust(2, '0')
  month = month.to_s.rjust(2, '0')
  "#{year}#{month}#{dom}"
end

def get_event_type_abbr(event_title)
  event_types = {
    'AG Finanzen' => 'AG.Finanz',
    'ISEK' => 'AG.ISEK',
    'Kita' => 'AG.Kita',
    'Kommunalpolitik' => 'AG.Politik.Schule',
    'Kriminalverhütung' => 'AG.Krimi',
    'Betreuung' => 'AG.Nachschul.Betreuung',
    'Schulentwicklung' => 'AG.Schulentwicklung',
    'Stadtkern' => 'AG.Stadtkern',
    'Feuerwehr' => 'BuF',
    'Finanzen' => 'Finanz',
    'Gemeindewahl' => 'GW',
    'Hauptausschuss' => 'HA',
    'JUBIKU' => 'JUBIKU',
    'Jugend' => 'KuJ',
    'Klimaschutz' => 'KEA',
    'Ratsversammlung' => 'RV',
    'Rechnungsprüfung' => 'RP',
    'Kultur' => 'SSK',
    'Schulleiterwahl' => 'SLW',
    'Seniorenbeirat' => 'SB',
    'Soziales' => 'SJuS',
    'Stadtentwicklung' => 'ASU'
  }
  event_types.each do |keyword, abbr|
    return abbr if event_title.include?(keyword)
  end
  'NA'
end

def generate_pdf_name(pdf_url, event_date, event_type_abbr, top_number, file_index, pdf_type)
  suffix = pdf_type == 'Vorlage' ? 'V' : 'S'
  top_number = top_number.to_s.gsub(/\D/, '').rjust(2, '0')
  file_name = "#{event_date}.#{event_type_abbr}.TOP#{top_number}"
  file_name += ".#{file_index}" if file_index > 1
  file_name += ".#{suffix}.pdf"
  file_name
end

def scrape_vorlagen_details(vorlagen_url, event_date, event_type_abbr, top_number)
  puts "Zugriff auf Vorlagenseite: #{vorlagen_url}"
  begin
    if valid_url?(vorlagen_url)
      document = Nokogiri::HTML(open(vorlagen_url))

      vorlagenbezeichnung = document.at_css('span#vobetreff a') ? document.at_css('span#vobetreff a').text.strip : ''
      puts "Vorlagenbezeichnung: #{vorlagenbezeichnung}"

      vorlagenprotokolltext = document.at_css('#mainContent') ? document.at_css('#mainContent').text.gsub(/\s+/, ' ').strip : ''
      puts "Vorlagenprotokolltext: #{vorlagenprotokolltext}"

      vorlagen_pdf_url = document.at_css('a.doclink.pdf') ? "https://www.sitzungsdienst-schenefeld.de/bi/#{document.at_css('a.doclink.pdf')['href']}" : ''
      puts "Vorlagen-PDF-URL: #{vorlagen_pdf_url}"

      sammel_pdf_url = document.xpath("//a[contains(@data-simpletooltip-text, 'Vorlage-Sammeldokument')]").first ? "https://www.sitzungsdienst-schenefeld.de/bi/#{document.xpath("//a[contains(@data-simpletooltip-text, 'Vorlage-Sammeldokument')]").first['href']}" : ''
      puts "Vorlagen-Sammel-PDF-URL: #{sammel_pdf_url}"

      file_index = 1
      vorlagen_pdf_name = generate_pdf_name(vorlagen_pdf_url, event_date, event_type_abbr, top_number, file_index, 'Vorlage')
      if !sammel_pdf_url.empty?
        file_index += 1
        sammel_pdf_name = generate_pdf_name(sammel_pdf_url, event_date, event_type_abbr, top_number, file_index, 'Sammel')
      else
        sammel_pdf_name = ''
      end

      {
        'vorlagenbezeichnung' => vorlagenbezeichnung,
        'vorlagenprotokolltext' => vorlagenprotokolltext,
        'vorlagen_pdf_url' => vorlagen_pdf_url,
        'vorlagen_pdf_name' => vorlagen_pdf_name,
        'sammel_pdf_url' => sammel_pdf_url,
        'sammel_pdf_name' => sammel_pdf_name
      }
    else
      puts "Ungültige Vorlagen-URL: #{vorlagen_url}"
      return nil
    end
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Vorlagenseite: #{vorlagen_url}"
    puts "Fehlermeldung: #{e.message}"
    return nil
  end
end

def scrape_top_details(top_url, event_date, event_type_abbr, top_number)
  puts "Zugriff auf TOP-Seite: #{top_url}"
  begin
    if valid_url?(top_url)
      document = Nokogiri::HTML(open(top_url))

      main_content_elements = document.css('#mainContent div.expandedDiv, #mainContent div.expandedTitle')
      top_protokolltext = main_content_elements.map { |element| element.text.strip }.join(" ").gsub(/\s+/, ' ')
      puts "TOP-Protokolltext: #{top_protokolltext}"

      vorlagen_betreff_element = document.at_css('span#vobetreff a')
      vorlagen_data = nil
      if vorlagen_betreff_element
        vorlagen_betreff_text = vorlagen_betreff_element.text.strip
        vorlagen_url = "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlagen_betreff_element['href']}"
        puts "Vorlagen-Betreff gefunden: #{vorlagen_betreff_text}, Vorlagen-URL: #{vorlagen_url}"
        vorlagen_data = scrape_vorlagen_details(vorlagen_url, event_date, event_type_abbr, top_number)
      else
        puts "Keine Vorlage vorhanden."
      end

      {
        'top_protokolltext' => top_protokolltext,
        'vorlagen_data' => vorlagen_data
      }
    else
      puts "Ungültige TOP-URL: #{top_url}"
      return { 'top_protokolltext' => nil, 'vorlagen_data' => nil }
    end
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die TOP-Seite: #{top_url}"
    puts "Fehlermeldung: #{e.message}"
    return { 'top_protokolltext' => nil, 'vorlagen_data' => nil }
  end
end

def scrape_event_details(event_url, event_date, event_type_abbr)
  puts "Zugriff auf Sitzungsseite: #{event_url}"
  begin
    if valid_url?(event_url)
      document = Nokogiri::HTML(open(event_url))

      event_data = []
      document.css('tr').each do |row|
        index_number_element = row.at_css('td.tonr a')
        index_number = index_number_element ? index_number_element.text.strip : ''

        betreff_element = row.at_css('td.tobetreff div a') || row.at_css('td.tobetreff div')
        betreff = betreff_element ? betreff_element.text.strip : ''

        top_link = row.at_css('td.tobetreff div a')
        top_url = top_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{top_link['href']}" : ""

        vorlage_link = row.at_css('td.tovonr a')
        vorlage_text = vorlage_link ? vorlage_link.text.strip : ""
        vorlage_url = vorlage_link ? "https://www.sitzungsdienst-schenefeld.de/bi/#{vorlage_link['href']}" : ""

        if !index_number.empty? && !betreff.empty?
          top_data = scrape_top_details(top_url, event_date, event_type_abbr, index_number)

          event_data << {
            'index_number' => index_number,
            'betreff' => betreff,
            'top_url' => top_url,
            'vorlage_text' => vorlage_text,
            'vorlage_url' => vorlage_url,
            'top_data' => top_data
          }
          puts "Gefunden: #{index_number}, Betreff: #{betreff}, TOP-URL: #{top_url}, Vorlage: #{vorlage_text}, Vorlage URL: #{vorlage_url}"
        end
      end
      event_data
    else
      puts "Ungültige Sitzungs-URL: #{event_url}"
      return []
    end
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Sitzungsseite: #{event_url}"
    puts "Fehlermeldung: #{e.message}"
    return []
  end
end

def drop_tables
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS data")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS calendar_events")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS event_details")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS top_details")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS vorlagen_details")
end

def create_tables
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS calendar_events (id INTEGER PRIMARY KEY, date TEXT, time TEXT, title TEXT, url TEXT, room TEXT)")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS event_details (id INTEGER PRIMARY KEY, calendar_event_id INTEGER, index_number TEXT, betreff TEXT, top_url TEXT, vorlage_id TEXT, vorlage_url TEXT, FOREIGN KEY (calendar_event_id) REFERENCES calendar_events(id))")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS top_details (id INTEGER PRIMARY KEY, event_detail_id INTEGER, top_protokolltext TEXT, FOREIGN KEY (event_detail_id) REFERENCES event_details(id))")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS vorlagen_details (id INTEGER PRIMARY KEY, top_detail_id INTEGER, vorlage_id TEXT, vorlagenprotokolltext TEXT, vorlagen_pdf_url TEXT, vorlagen_pdf_name TEXT, sammel_pdf_url TEXT, sammel_pdf_name TEXT, vorlagen_rename_url TEXT, sammel_rename_url TEXT, FOREIGN KEY (top_detail_id) REFERENCES top_details(id))")

end

def scrape_calendar_data(year, month)
  url = "https://www.sitzungsdienst-schenefeld.de/bi/si010_r.asp?MM=#{month}&YY=#{year}"
  puts "Zugriff auf Kalenderseite: #{url}"
  begin
    if valid_url?(url)
      document = Nokogiri::HTML(open(url))

      calendar_data = []
      db = SQLite3::Database.new('data.sqlite')

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
          puts "Eventtitel: #{title}"
          url = "https://www.sitzungsdienst-schenefeld.de/bi/#{title_element['href']}"
          room = room_element.text
          formatted_date = extract_and_format_date(dow, dom, month, year)

          event_type_abbr = get_event_type_abbr(title)

          calendar_event = {
            'date' => formatted_date,
            'time' => time,
            'title' => title,
            'url' => url,
            'room' => room
          }
          db.execute("INSERT INTO calendar_events (date, time, title, url, room) VALUES (?, ?, ?, ?, ?)", calendar_event.values_at('date', 'time', 'title', 'url', 'room'))
          calendar_event_id = db.last_insert_row_id

          event_data = scrape_event_details(url, formatted_date, event_type_abbr)
          event_data.each do |event_detail|
            event_detail['calendar_event_id'] = calendar_event_id
            db.execute("INSERT INTO event_details (calendar_event_id, index_number, betreff, top_url, vorlage_id, vorlage_url) VALUES (?, ?, ?, ?, ?, ?)", [calendar_event_id, event_detail['index_number'], event_detail['betreff'], event_detail['top_url'], event_detail['vorlage_text'], event_detail['vorlage_url']])
            event_detail_id = db.last_insert_row_id
            top_data = event_detail['top_data']
            if top_data
              top_detail = {
                # Use the event_detail_id from the previous insertion
                'event_detail_id' => event_detail_id,
                'top_protokolltext' => top_data['top_protokolltext']
              }
              # Insert the top detail into the top_details table and retrieve the inserted ID
              db.execute("INSERT INTO top_details (event_detail_id, top_protokolltext) VALUES (?, ?)", [event_detail_id, top_detail['top_protokolltext']])
              top_detail_id = db.last_insert_row_id

             vorlagen_data = top_data['vorlagen_data']
             if vorlagen_data
              puts "Vorlagen-Daten gefunden:"
              puts "Vorlagenbezeichnung: #{vorlagen_data['vorlagenbezeichnung']}"
              puts "Vorlagenprotokolltext: #{vorlagen_data['vorlagenprotokolltext']}"
              puts "Vorlagen-PDF-URL: #{vorlagen_data['vorlagen_pdf_url']}"
              puts "Vorlagen-PDF-Name: #{vorlagen_data['vorlagen_pdf_name']}"
              puts "Vorlagen-Sammel-PDF-URL: #{vorlagen_data['sammel_pdf_url']}"
              puts "Vorlagen-Sammel-PDF-Name: #{vorlagen_data['sammel_pdf_name']}"

              vorlagen_detail = {
                'top_detail_id' => top_detail_id,
                'vorlage_id' => event_detail['vorlage_text'],
                'vorlagenprotokolltext' => vorlagen_data['vorlagenprotokolltext'],
                'vorlagen_pdf_url' => vorlagen_data['vorlagen_pdf_url'],
                'vorlagen_pdf_name' => vorlagen_data['vorlagen_pdf_name'],
                'sammel_pdf_url' => vorlagen_data['sammel_pdf_url'],
                'sammel_pdf_name' => vorlagen_data['sammel_pdf_name'],
                'vorlagen_rename_url' => "#{vorlagen_data['vorlagen_pdf_url']}#filename=#{vorlagen_data['vorlagen_pdf_name']}",
                'sammel_rename_url' => "#{vorlagen_data['sammel_pdf_url']}#filename=#{vorlagen_data['sammel_pdf_name']}"
                }
              db.execute("INSERT INTO vorlagen_details (top_detail_id, vorlage_id, vorlagenprotokolltext, vorlagen_pdf_url, vorlagen_pdf_name, sammel_pdf_url, sammel_pdf_name, vorlagen_rename_url, sammel_rename_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [vorlagen_detail['top_detail_id'], vorlagen_detail['vorlage_id'], vorlagen_detail['vorlagenprotokolltext'], vorlagen_detail['vorlagen_pdf_url'], vorlagen_detail['vorlagen_pdf_name'], vorlagen_detail['sammel_pdf_url'], vorlagen_detail['sammel_pdf_name'], vorlagen_detail['vorlagen_rename_url'], vorlagen_detail['sammel_rename_url']])
             else
              puts "Keine Vorlagen-Daten gefunden."
            end
            end
          end

          calendar_data << calendar_event
          puts "Datum: #{formatted_date}, Zeit: #{time}, Titel: #{title}, URL: #{url}, Raum: #{room}"
        end
      end

      db.close
      calendar_data
    else
      puts "Ungültige Kalender-URL: #{url}"
      return []
    end
  rescue OpenURI::HTTPError => e
    puts "Fehler beim Zugriff auf die Kalenderseite: #{url}"
    puts "Fehlermeldung: #{e.message}"
    return []
  end
end

# Drop existing tables
#drop_tables

def tables_exist?
  begin
    ScraperWiki.sqliteexecute("SELECT 1 FROM calendar_events LIMIT 1")
    true
  rescue SQLite3::SQLException
    false
  end
end

# Create new tables with the desired column names if they don't exist
create_tables unless tables_exist?

# Define the range of months to scrape
month_range = [
    [2006, 2], [2006, 3], [2006, 4], [2006, 5], [2006, 6], [2006, 7], [2006, 8], [2006, 9], [2006, 10], [2006, 11], [2006, 12],
    [2007, 1], [2007, 2], [2007, 3], [2007, 4], [2007, 5], [2007, 6], [2007, 7], [2007, 8], [2007, 9], [2007, 10], [2007, 11], [2007, 12],
    [2008, 1], [2008, 2], [2008, 3], [2008, 4], [2008, 5], [2008, 6], [2008, 7], [2008, 8], [2008, 9], [2008, 10], [2008, 11], [2008, 12],
    [2009, 1], [2009, 2], [2009, 3], [2009, 4], [2009, 5], [2009, 6], [2009, 7], [2009, 8], [2009, 9], [2009, 10], [2009, 11], [2009, 12],
    [2010, 1], [2010, 2], [2010, 3], [2010, 4], [2010, 5], [2010, 6], [2010, 7], [2010, 8], [2010, 9], [2010, 10], [2010, 11], [2010, 12],
    [2011, 1], [2011, 2], [2011, 3], [2011, 4], [2011, 5], [2011, 6], [2011, 7], [2011, 8], [2011, 9], [2011, 10], [2011, 11], [2011, 12],
    [2012, 1], [2012, 2], [2012, 3], [2012, 4], [2012, 5], [2012, 6], [2012, 7], [2012, 8], [2012, 9], [2012, 10], [2012, 11], [2012, 12],
    [2013, 1], [2013, 2], [2013, 3], [2013, 4], [2013, 5], [2013, 6], [2013, 7], [2013, 8], [2013, 9], [2013, 10], [2013, 11], [2013, 12],
    [2014, 1], [2014, 2], [2014, 3], [2014, 4], [2014, 5], [2014, 6], [2014, 7], [2014, 8], [2014, 9], [2014, 10], [2014, 11], [2014, 12],
    [2015, 1], [2015, 2], [2015, 3], [2015, 4], [2015, 5], [2015, 6], [2015, 7], [2015, 8], [2015, 9], [2015, 10], [2015, 11], [2015, 12],
    [2016, 1], [2016, 2], [2016, 3], [2016, 4], [2016, 5], [2016, 6], [2016, 7], [2016, 8], [2016, 9], [2016, 10], [2016, 11], [2016, 12],
    [2017, 1], [2017, 2], [2017, 3], [2017, 4], [2017, 5], [2017, 6], [2017, 7], [2017, 8], [2017, 9], [2017, 10], [2017, 11], [2017, 12],
    [2018, 1], [2018, 2], [2018, 3], [2018, 4], [2018, 5], [2018, 6], [2018, 7], [2018, 8], [2018, 9], [2018, 10], [2018, 11], [2018, 12],
    [2019, 1], [2019, 2], [2019, 3], [2019, 4], [2019, 5], [2019, 6], [2019, 7], [2019, 8], [2019, 9], [2019, 10], [2019, 11], [2019, 12],
    [2020, 1], [2020, 2], [2020, 3], [2020, 4], [2020, 5], [2020, 6], [2020, 7], [2020, 8], [2020, 9], [2020, 10], [2020, 11], [2020, 12],
    [2021, 1], [2021, 2], [2021, 3], [2021, 4], [2021, 5], [2021, 6], [2021, 7], [2021, 8], [2021, 9], [2021, 10], [2021, 11], [2021, 12]
]

# Scrape the data for each month in the range
month_range.each do |year, month|
  calendar_data = scrape_calendar_data(year.to_s, month.to_s)
  # Print the scraped data for debugging
  # puts calendar_data
end

# Print the scraped data for debugging
puts calendar_data
