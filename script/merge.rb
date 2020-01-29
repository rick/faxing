#!/usr/bin/env ruby

require "optparse"
require "json"
require "pp"

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("--from=SENDER", "name of data/<sender>.json file to fetch sender data from (default: me)") do |sender|
	  options["sender"] = sender  	 
  end

  opts.on("--to=RECIPIENT", "name of data/<recipient>.json file to fetch recipient data from") do |recipient|
	  options["recipient"] = recipient  	 
  end

  opts.on("--template=TEMPLATE", "name of templates/<template>.tex file to merge (default: letter)") do |template|
    options["template"] = template
  end
end.parse!

def current_path
  File.dirname(__FILE__)
end

def path_to(*paths)
  segments = [ current_path, ".." ] + paths
  File.join(*segments)
end

def person_data(which)
  file = path_to "data", "#{which}.json"
  data = JSON.parse(File.read(file))
  raise "#{file} does not have name data" unless data["name"]
  raise "#{file} does not have address data" unless data["address"]
  data
end

def read_template(which)
  file = path_to "templates", "#{which}.tex"
  File.read(file)
end

def replace(text, target, replacement)
  text.gsub(%r{\(\(#{target}\)\)}, replacement)
end

def merge(template, body, sender, recipient)
  text = replace(template, "NAME", sender["name"])
  text = replace(text, "ADDRESS", sender["address"].join(" \\ "))
  text = replace(text, "RECIPIENT", [ recipient["name"], recipient["address"] ].flatten.join(" \\ "))
  text = replace(text, "BODY", body)
end

options["sender"] ||= "me"

if options["recipient"]
  recipient_file = path_to "data", "#{options["recipient"]}.json"
else
  puts options.usage
  exit 1
end

options["template"] ||= "letter"

sender_data = person_data options["sender"]
recipient_data = person_data options["recipient"]
template_data = read_template options["template"]
body = STDIN.read

final = merge(template_data, body, sender_data, recipient_data)
puts final

