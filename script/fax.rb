#!/usr/bin/env ruby

require "phaxio"

def die_usage
  puts "Usage:\n #{$0} <phone-number> <file>\nSet PHAXIO_API_KEY and PHAXIO_API_SECRET in your environment."
  exit 1
end

Phaxio.api_key = ENV["PHAXIO_API_KEY"] || die_usage
Phaxio.api_secret = ENV["PHAXIO_API_SECRET"] || die_usage

phone_number = ARGV.shift || die_usage
fax_filename = ARGV.shift || die_usage

puts "Now sending fax from [#{fax_filename}] to phone number [#{phone_number}]..."
fax_file = File.open fax_filename, 'rb'
Phaxio::Fax.create to: phone_number, file: fax_file

