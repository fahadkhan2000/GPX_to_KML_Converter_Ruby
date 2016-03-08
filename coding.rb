require 'nokogiri'
require 'rubygems'

  class Coding
=begin
    text = File.read('GPX.xml')
    new_node_name_1 = text.gsub(/trkpt/ , "newNodeName_trkpt")
    new_node_name_2 = new_node_name_1.gsub(/time/ , "new_time_node")
    puts new_node_name_2

    write_handler = File.new("k.out", "w")
    write_handler.puts(new_node_name_2).to_s
    write_handler.close

    text = File.read('GPX.xml')
    doc = Nokogiri::XML(text)

    doc.search('//time').each do |node|
      node.children.remove

      out_handler = File.new("kaster.out", "w")
      out_handler.puts(text).to_s
      out_handler.close
    end


    puts "Running....!!!!!!"
    f = File.open('gpx.xml')
    doc = Nokogiri::XML(f)
    f.close
    print doc
    mydoc = doc
    new_content = mydoc.gsub("trkpt" , "Style")
    write_handler = File.new("kml.out", "w")
    write_handler.puts(new_content).to_s
    write_handler.close
=end


