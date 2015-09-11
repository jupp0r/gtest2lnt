#!/usr/bin/env ruby

require "docopt"
require "nokogiri"
require "json"

doc = <<DOCOPT
gtest2lnt converts google test xml output to lnt json blobs
that can be submitted to a lnt server.

Usage:
  gtest2lnt convert <file>
  gtest2lnt submit <file>

DOCOPT

begin
  options = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit 1
end

if options['convert']
  output_data = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

  File.open(options['<file>']) do |f|
    xml_doc = Nokogiri::XML(f) do |config|
      config.options = Nokogiri::XML::ParseOptions::NONET
    end
    xml_doc.xpath('/testsuites').each do |xml_testsuites|
      testsuites_name = "#{xml_testsuites['name']}"
      xml_testsuites.xpath('testsuite').each do |xml_testsuite|
        testsuite_name = "#{xml_testsuite['name']}"
        xml_testsuite.xpath('testcase').each do |xml_test|
          puts xml_test.inspect
          test_name = "#{xml_testsuite['name']}"
          test_full_name = "#{testsuites_name}.#{testsuite_name}.#{test_name}"
          output_data['Tests'] = [] if output_data['Tests'].empty?
          output_data['Tests'].push({"Name" => test_full_name}, "Info" => {}, "Data" => {})
        end
      end
    end

    output_data['Machine']['Name'] = `uname -n`
    output_data['Run']['Start Time'] = Time.now.utc
    output_data['Run']['End Time'] = Time.now.utc
    output_data['Run']['Info']['__report_version__'] = 1

    puts JSON.generate(output_data)
  end
end

if options['submit']
  puts "submit #{options['<file>']}"
end
