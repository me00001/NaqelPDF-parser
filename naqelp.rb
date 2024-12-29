require 'pdf-reader'
require 'json'
require 'csv'

def extract_waybill_info(pdf_file_path)
  begin
    reader = PDF::Reader.new(pdf_file_path)
    waybill_numbers = []
    origins = []
    destinations = []

    reader.pages.each do |page|
      text = page.text

      # Extract WayBill Number
      if text =~ /WayBill No:\s*(\d+)/
        waybill_numbers << $1
      end

      # Extract Origin
      if text =~ /Origin:\s*([A-Z]+)/i
        origins << $1
      end

      # Extract Destination
      if text =~ /Destination:\s*([A-Z]+)/i
        destinations << $1
      end
    end

    {
      waybill_numbers: waybill_numbers,
      origins: origins,
      destinations: destinations
    }
  rescue PDF::Reader::MalformedPDFError => e
    puts "Error reading PDF #{pdf_file_path}: #{e.message}"
    nil
  rescue => e
    puts "An error occurred while reading PDF #{pdf_file_path}: #{e.message}"
    nil
  end
end

# Check if a directory path was provided as an argument
if ARGV.length != 3
  puts "Usage: ruby naqelp.rb path/to/PDF/directory output.json output.csv"
  exit 1
end

directory_path = ARGV[0]
json_output_file_path = ARGV[1]
csv_output_file_path = ARGV[2]

# Initialize an array to hold all extracted information
extracted_data = []


# Iterate over all PDF files in the specified directory
Dir.glob(File.join(directory_path, '*.pdf')) do |pdf_file_path|
  info = extract_waybill_info(pdf_file_path)

  if info
    puts "File: #{pdf_file_path}"
    puts "WayBill Numbers: #{info[:waybill_numbers].join(', ')}" if info[:waybill_numbers].any?
    puts "Origins: #{info[:origins].join(', ')}" if info[:origins].any?
    puts "Destinations: #{info[:destinations].join(', ')}" if info[:destinations].any?
    puts "-" * 40 # Separator for clarity
    extracted_data << { file: pdf_file_path }.merge(info)
  else
    puts "Information not found in file: #{pdf_file_path}"
    extracted_data << { file: pdf_file_path, error: "Information not found", waybill_numbers: [], origins: [], destinations: [] }
  end
end

# Write the extracted data to a JSON file
File.open(json_output_file_path, 'w') do |file|
  file.write(JSON.pretty_generate(extracted_data))
  puts "Extracted information has been written to #{json_output_file_path}"
end

# Write the extracted data to a CSV file
CSV.open(csv_output_file_path, 'w') do |csv|
  # Add headers to the CSV
  csv << ['File', 'WayBill', 'Origin', 'Destination']

  extracted_data.each do |data|
    # Get the maximum number of entries for waybills, origins, and destinations
    max_entries = [data[:waybill_numbers].size, data[:origins].size, data[:destinations].size].max

    max_entries.times do |i|
      # Prepare the row data
      row = [
        data[:file], 
        data[:waybill_numbers][i] || '',  # WayBill
        data[:origins][i] || '',           # Origin
        data[:destinations][i] || ''       # Destination
      ]
      
      # Write the row to the CSV
      csv << row
    end
  end
  puts "Extracted information has been written to #{csv_output_file_path}"
end
