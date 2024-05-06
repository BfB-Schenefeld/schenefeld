require 'scraperwiki'

def drop_tables
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS calendar_events")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS event_details")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS top_details")
  ScraperWiki.sqliteexecute("DROP TABLE IF EXISTS vorlagen_details")
end

def create_tables
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS calendar_events (id INTEGER PRIMARY KEY, date TEXT, time TEXT, title TEXT, url TEXT, room TEXT)")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS event_details (id INTEGER PRIMARY KEY, calendar_event_id INTEGER, index_number TEXT, betreff TEXT, top_url TEXT, vorlage_id TEXT, vorlage_url TEXT, FOREIGN KEY (calendar_event_id) REFERENCES calendar_events(id))")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS top_details (id INTEGER PRIMARY KEY, event_detail_id INTEGER, top_protokolltext TEXT, FOREIGN KEY (event_detail_id) REFERENCES event_details(id))")
  ScraperWiki.sqliteexecute("CREATE TABLE IF NOT EXISTS vorlagen_details (id INTEGER PRIMARY KEY, top_detail_id INTEGER, vorlage_id TEXT, vorlagenprotokolltext TEXT, vorlagen_pdf_url TEXT, sammel_pdf_url TEXT, FOREIGN KEY (top_detail_id) REFERENCES top_details(id))")
end

def insert_test_data
  # Insert a calendar event
  calendar_event_id = ScraperWiki.sqliteexecute("INSERT INTO calendar_events (date, time, title, url, room) VALUES (?, ?, ?, ?, ?)", ['2024-03-01', '09:00', 'Test Event', 'https://example.com/event', 'Room A'])
  calendar_event_id = calendar_event_id.last

  # Insert an event detail
  event_detail_id = ScraperWiki.sqliteexecute("INSERT INTO event_details (calendar_event_id, index_number, betreff, top_url, vorlage_id, vorlage_url) VALUES (?, ?, ?, ?, ?, ?)", [calendar_event_id, '1', 'Test Betreff', 'https://example.com/top', 'V1', 'https://example.com/vorlage'])
  event_detail_id = event_detail_id.last

  # Insert a top detail
  top_detail_id = ScraperWiki.sqliteexecute("INSERT INTO top_details (event_detail_id, top_protokolltext) VALUES (?, ?)", [event_detail_id, 'Test TOP Protokolltext'])
  top_detail_id = top_detail_id.last

  # Insert a vorlagen detail
  ScraperWiki.sqliteexecute("INSERT INTO vorlagen_details (top_detail_id, vorlage_id, vorlagenprotokolltext, vorlagen_pdf_url, sammel_pdf_url) VALUES (?, ?, ?, ?, ?)", [top_detail_id, 'V1', 'Test Vorlagenprotokolltext', 'https://example.com/vorlagen.pdf', 'https://example.com/sammel.pdf'])
end

# Drop existing tables
drop_tables

# Create new tables
create_tables

# Insert test data
insert_test_data

# Retrieve data from the tables
calendar_events = ScraperWiki.select("* FROM calendar_events")
event_details = ScraperWiki.select("* FROM event_details")
top_details = ScraperWiki.select("* FROM top_details")
vorlagen_details = ScraperWiki.select("* FROM vorlagen_details")

puts "Calendar Events:"
puts calendar_events
puts "Event Details:"
puts event_details
puts "TOP Details:"
puts top_details
puts "Vorlagen Details:"
puts vorlagen_details
