#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'unicode_utils/downcase'
require 'zlib'
require 'dstk'

# RELEVANT INFO:
# Twitter API info: https://dev.twitter.com/docs/platform-objects/tweets
# Geocoding: http://www.datasciencetoolkit.org/

# wanted bounding box
bounding_box = {
  # CONTINENTAL USA
  ne: { lat: 49.590370, lon: -66.932640 },
  sw: { lat: 24.949320, lon: -125.001106 }
}
# twitter attributes to keep
# just copy the lines and adapt to the attributes you want
# default ones: text, coordinates
def transfer_attr(tweet, final_tweet)
  final_tweet['created_at'] = tweet['created_at'] unless tweet['created_at'].nil?
  unless tweet['user'].nil?
    final_tweet['user'] = Hash.new
    final_tweet['user']['location'] = tweet['user']['location'] unless tweet['user']['location'].nil?
  end
end
# output_file is in the same directory as inputfile but with a '_parsed' at the end

########################################################################################
########################################################################################
########################## NO NEED TO CHANGE ANYTHING BELOW ############################
########################################################################################
########################################################################################

# path to file with all file that have tweets (passed as argument)
file_list = ARGV[0]

# check if a coordinates point is wthin a certain box
def within_box?(bounding_box, point_lat, point_lon)
  box_lons = [bounding_box[:ne][:lon], bounding_box[:sw][:lon]]
  box_lats = [bounding_box[:ne][:lat], bounding_box[:sw][:lat]]
  return (point_lon.between?(box_lons.min, box_lons.max) && point_lat.between?(box_lats.min, box_lats.max))
end

dstk = DSTK::DSTK.new

File.open(file_list).read.each_line do |tweets_filename|

  # remove new line at the end of line
  tweets_filename.chomp!

  # set output filename adding _parsed at the end, and on the current directory
  output_filename = tweets_filename.rpartition('/').last.partition('.').first + "_parsed"
  output_file = File.open(output_filename, "w")

  # print init time
  puts "> started '#{tweets_filename}' at #{Time.now}"

  # skips if line is commented
  next if tweets_filename[0] == '#'

  tweets_file = Zlib::GzipReader.new(open(tweets_filename), {encoding: Encoding::UTF_8})
  output_string = ""
  begin
    tweet_num = 0
    tweets_file.each_line do |tweet|
      # parse tweet to hash form JSON
      tweet = JSON.parse(tweet)

      # skip null tweets
      next if tweet['text'].nil?

      # replace text removing non-UTF8 chars
      tweet['text'] = UnicodeUtils.downcase(tweet['text'].encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '').delete("\n"))

      # if no coordinates given, tries to geocode user location
      if tweet['coordinates'].nil? and !tweet['user']['location'].nil? and !tweet['user']['location'].empty?

        # replace location removing non-UTF8 chars
        # also removes \n and ' (found out that DSK doesn't handle them very well)
        tweet['user']['location'] = UnicodeUtils.downcase(tweet['user']['location'].encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '').delete("\n", "'"))


        # gets coordinates from tweet using search
        # takes only th first result
        # loops until we have an asnwer, if exception raised we wait i*30 seconds
        i = 0
        coordinates = nil
        loop do
          begin
            coordinates = dstk.geocode(tweet['user']['location'])['results'][0]
            break
          rescue Exception => e
            # if more than 3 exceptions we skip tweet
            if (i > 3)
              puts "Exception found: " + e.message
              puts "\tSkiping tweet with location: " + tweet['user']['location']
              break
            else
              # each time we sleep more time untill we skip tweets
              i += 1
              sleep(30 * i)
            end
          end
        end

        # replace the coordinates with the location ones
        unless coordinates.nil?
          tweet['coordinates'] = {'coordinates' => [] }
          tweet['coordinates']['coordinates'].insert(0, coordinates['geometry']['location']['lng'])
          tweet['coordinates']['coordinates'].insert(1, coordinates['geometry']['location']['lat'])
        end
      end

      # if location is still nil, no coordinates were found, skips tweet
      next if tweet['coordinates'].nil?

      # tweet coordinates
      tweet_lat = tweet['coordinates']['coordinates'][1]
      tweet_lon = tweet['coordinates']['coordinates'][0]

      # if outside box skips tweet
      next unless within_box?(bounding_box, tweet_lat, tweet_lon)

      # setup final tweet with wanted attrbiutes
      final_tweet = Hash.new
      # default attributes
      final_tweet['text'] = tweet['text']
      final_tweet['coordinates'] = tweet['coordinates']
      # extra attributes
      transfer_attr(tweet, final_tweet)

      # execute R script to know state,county
      state_county = %x(Rscript lonlat2statecounty.R #{tweet_lon} #{tweet_lat}).partition(',')

      # skips tweet if coordinates are outside shapefile for continental US
      next if state_county.last.empty?

      final_tweet['coordinates']['state'] = state_county.first
      final_tweet['coordinates']['county'] = state_county.last

      # write tweets to output file
      tweet_num += 1
      output_string += JSON.generate(final_tweet) + "\n"

      # if it wrote 'enough' tweets writes to file
      if tweet_num == 2
        output_file.write(output_string)
        tweet_num = 0
        output_string = ""
        puts "> Added 1000 tweets at #{Time.now}"
      end
    end

    # print end time
    puts "> ended '#{tweets_filename}' at #{Time.now}"
  ensure
    # make sure we close file
    output_file.close
    tweets_file.close
  end
end

