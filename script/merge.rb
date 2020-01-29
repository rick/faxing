#!/usr/bin/env ruby

require "optparse"
require "json"
require "pathname"
require "tempfile"
require "pp"

options = {}

op = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]\n (provide message body on STDIN)"

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
end


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

def clean_fax_number(string)
  string.gsub(%r{[^0-9]}, '')
end

def extract_options(options, op)
  op.parse!
  sender_data, recipient_data, template_data = nil, nil, nil

  options["sender"] ||= "me"

  if options["recipient"]
    recipient_file = path_to "data", "#{options["recipient"]}.json"
  else
    puts op.parse("--help")
    exit 1
  end

  options["template"] ||= "letter"

  sender_data = person_data options["sender"]
  recipient_data = person_data options["recipient"]
  raise "file [#{recipient_file}] has no fax data" unless recipient_data["fax"]
  template_data = read_template options["template"]

  return [sender_data, recipient_data, template_data]
end

sender_data, recipient_data, template_data = extract_options(options, op)
fax_number = clean_fax_number(recipient_data["fax"])
body = STDIN.read

text = merge(template_data, body, sender_data, recipient_data)
pdf_file = make_pdf text

system("open #{pdf_file}")

puts "When ready, run:"
puts "bundle exec ruby script/fax.rb #{fax_number} #{pdf_file}"

