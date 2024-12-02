require 'pdf-reader'

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
if ARGV.length != 1
  puts "Usage: ruby naqelp.rb path/to/PDF/directory"
  exit 1
end

directory_path = ARGV[0]

# Iterate over all PDF files in the specified directory
Dir.glob(File.join(directory_path, '*.pdf')) do |pdf_file_path|
  info = extract_waybill_info(pdf_file_path)

  if info
    puts "File: #{pdf_file_path}"
    puts "WayBill Numbers: #{info[:waybill_numbers].join(', ')}" if info[:waybill_numbers].any?
    puts "Origins: #{info[:origins].join(', ')}" if info[:origins].any?
    puts "Destinations: #{info[:destinations].join(', ')}" if info[:destinations].any?
    puts "-" * 40 # Separator for clarity
  else
    puts "Information not found in file: #{pdf_file_path}"
  end
end
