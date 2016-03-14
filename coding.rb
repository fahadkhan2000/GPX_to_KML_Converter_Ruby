require 'nokogiri'
require 'rubygems'

class Coding
  def read_gpx(filename)
    coords = Array.new
    f = File.read(filename)
    gpx = Nokogiri::XML(f)
    gpx.remove_namespaces!
    error_count = 0

    trackpoints = gpx.xpath('//gpx/trk/trkseg/trkpt')
    trackpoints.each do |waypoint|
      w = {
          :lat => waypoint.xpath('@lat').to_s.to_f,
          :lon => waypoint.xpath('@lon').to_s.to_f,
          :time => self.class.proc_time(waypoint.xpath('time').children.first.to_s),
          :alt => waypoint.xpath('ele').children.first.to_s.to_f
      }
      if self.class.coord_valid?(w[:lat], w[:lon], w[:alt], w[:time])
        coords << w
      else
        error_count += 1
      end
    end
    coords = coords.sort { |b, c| b[:time] <=> c[:time] }
    {title: gpx.xpath('//gpx/trk/name').text, desc: gpx.xpath('//gpx/trk/desc').text, coords: coords}

    return coords
  end

  def self.proc_time(ts)
    if ts =~ /(\d{4})-(\d{2})-(\d{2})T(\d{1,2}):(\d{2}):(\d{2})Z/
      return Time.gm($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i).localtime
    end
  end

  def initialize
    @coords = Array.new
  end

  def self.coord_valid?(lat, lon, elevation, time)
    return true if lat and lon
    return false
  end

  def build_kml(epsilon)
    if epsilon.nil?
      epsilon = 30e-5
    end
    epsilon = epsilon.to_f
    @styles = build_styles()
    @files = add_files('test_gpx_file_1')

    kml_builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.kml('xmlns' => 'http://www.opengis.net/kml/2.2',
              'xmlns:gx' => 'http://www.google.com/kml/ext/2.2',
              'xmlns:kml' => 'http://www.opengis.net/kml/2.2',
              'xmlns:atom' => 'http://www.w3.org/2005/Atom') do

        xml.Document do
          xml.name "Converted from GPX file"
          xml.description {
            xml.cdata "<p>Converted using <b><a href='http://github.com/shakaman/gpx2kml' title='Go to gpx2kml on github'>Github</a></b></p>"
          }
          xml.visibility 1
          xml.open 1

          @styles.each do |s|
            xml.Style(:id => s[:id]) {
              xml.LineStyle {
                xml.color_ s[:LineStyle][:color]
                xml.width_ s[:LineStyle][:width]
              }
            }
          end

          # Tracks
          xml.Folder do
            xml.name "Tracks"
            xml.description "A list of tracks"
            xml.visibility 1
            xml.open 0

            i = 0
            @files.each do |gpx|
              coordes = read_gpx(gpx)

              xml.Placemark do
                xml.visibility 0
                xml.open 0
                xml.styleUrl "##{@styles[i][:id]}"
                xml.name 'kmlFile'
                xml.description 'this is kml file'
                xml.LineString do
                  xml.extrude true
                  xml.tessellate true
                  xml.altitudeMode "clampToGround"
                  xml.coordinates format_track(coordes, epsilon)
                end
              end
              i += 1
            end
          end
        end
      end
    end

    kml_text = kml_builder.to_xml
    puts kml_text
    out_handler = File.new("kml_output.out", "w")
    out_handler.puts(kml_text).to_s
    out_handler.close
  end

  def init_epsilon(epsilon = 10e-8)
    @epsilon = epsilon
    return epsilon
  end

  def build_styles
    styles = Array.new
    styles << {id: 'red', LineStyle: {color: 'C81400FF', width: 4}}
    styles << {id: 'blue', LineStyle: {color: 'C8FF7800', width: 4}}
    styles << {id: 'pink', LineStyle: {color: '96F0FF14', width: 4}}
    styles << {id: 'green', LineStyle: {color: 'C878FF00', width: 4}}
    styles << {id: 'orange', LineStyle: {color: 'C81478FF', width: 4}}
    styles << {id: 'dark_green', LineStyle: {color: '96008C14', width: 4}}
    styles << {id: 'pink2', LineStyle: {color: 'C8A078F0', width: 4}}
  end

  def format_track(coords, epsilon)
    points = Array.new
    coords.each do |c|
      points << {lon: c[:lon], lat: c[:lat], alt: c[:alt]}
    end
    points_list = simplify_line(points)
    track = ""
    points_list.each do |c|
      track << "#{c[:lon]}, #{c[:lat]}, #{c[:alt]}, \n"
    end

    return track
  end

  def simplify_line(points)
    dmax = 0
    index = 0

    (1..(points.length - 1)).each do |i|
      d = perpendicular_distance(points[i], points.first, points.last)
      if d > dmax
        index = i
        dmax = d
      end
    end

    epsilon = init_epsilon()
    if dmax >= epsilon
      results_1 = simplify_line(points[0..index])
      results_2 = simplify_line(points[index..-1])

      results_1[0..-2] + results_2
    else
      [points.first, points.last]
    end
  end

  def perpendicular_distance(point, line_start, line_end)
    line = {
        start: {
            x: line_start[:lat].to_f,
            y: line_start[:lon].to_f
        },
        end: {
            x: line_end[:lat].to_f,
            y: line_end[:lon].to_f
        }
    }
    point = {x: point[:lat].to_f, y: point[:lon].to_f}

    numerator = ((line[:end][:x] - line[:start][:x])*(line[:start][:y] - point[:y]) - (line[:start][:x] - point[:x])*(line[:end][:y] - line[:start][:y]))
    denominator = (line[:end][:x] - line[:start][:x])**2 + (line[:end][:y] - line[:start][:y])**2

    numerator.abs/denominator**0.5
  end

  def add_files(files)
    @files = files.split(',')
  end

end

Coding.new.read_gpx('test_gpx_file_1')
Coding.new.build_kml(nil)
