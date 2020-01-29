#!/usr/bin/env ruby

require "optparse"
require "json"
require "pathname"
require "tempfile"
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

def normalize(path)
  Pathname.new(path).realpath
end

def path_to(*paths)
  segments = [ current_path, ".." ] + paths
  normalize(File.join(*segments))
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

def replace(lines, target, replacement)
  lines.each { |line| line.gsub!(%r{\(\(#{target}\)\)}m, replacement) }
end

def merge(template, body, sender, recipient)
  lines = template.split("\n")
  replace(lines, "NAME", sender["name"])
  replace(lines, "ADDRESS", sender["address"].join(' \\\\\\\\ '))
  replace(lines, "RECIPIENT", [ recipient["name"], recipient["address"] ].flatten.join(' \\\\\\\\ '))
  replace(lines, "BODY", body)
  lines.join("\n")
end

def make_pdf(text)
  tmp_dir = path_to("tmp")
  file = Tempfile.create(["output", ".tex"], tmp_dir)
  pp text
  file.write(text)
  file.flush
  file_path = normalize(file.path)
  system(%Q{pdflatex -interaction=batchmode -output-directory=#{tmp_dir} "#{file_path}"})
  pdf_file = file_path.sub(/\.tex/, ".pdf")
  if File.exists?(pdf_file)
    return pdf_file
  else
    log_file = file_path.sub(/\.tex/, ".log")
    raise "Could not find pdf file [#{pdf_file}] -- check log output from: [#{log_file}]?"
  end
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

text = merge(template_data, body, sender_data, recipient_data)
pdf_file = make_pdf text

system("open #{pdf_file}")

