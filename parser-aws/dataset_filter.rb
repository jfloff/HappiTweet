#!/usr/bin/env ruby

# Parses multiple tweet files
#
# Given a file with multiple files, it downloads each file and parses it.
# Parsing of that file consists of filtering of files where tweets:
#   1) Either have a twitter geotag JSON field, or has a
#      location got Geolocation services
#   2) Are within a certain bounding box, previously defined below
# Finally, filtered tweets are written to an output file, and the error ones
# are signaled in a errors file.
#
# Parameters:
#   ARGV[0]: text file with a list of files do download and parse tweets from
#
# Constants:
#   bounding_box: tweets location are filtered according to this bounding box
#   transfer_attr: function that defines what tweet attributes do we keep
#   step: ammount of tweets to parse before we write to the file
#
# Return:
#   Returns a parsed file for each file in the file list, that has the same
#   name as the original file, with ends in '_parsed'.
#   An error file is also output, its name is the same as the original ending
#   with '_error'.
#
# Example:
#   $ ruby dataset_filter.rb ../data/file_list.txt


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

# step for saved tweets and parsed tweets
step = 1000

########################################################################################################################
########################################################################################################################
########################################### NO NEED TO CHANGE ANYTHING BELOW  ##########################################
########################################################################################################################
########################################################################################################################

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

  # skips if line is commented
  next if tweets_filename[0] == '#'

  # remove new line at the end of line
  tweets_filename.chomp!

  # print init time
  puts "> [#{Time.now}] started '#{tweets_filename}' parse"

  puts "> [#{Time.now}] downloading '#{tweets_filename}'"
  tweets_file = Zlib::GzipReader.new(open(tweets_filename), {encoding: Encoding::UTF_8})
  puts "> [#{Time.now}] finished '#{tweets_filename}' download"

  output_tweets = Array.new
  output_error_tweets = Array.new

  tweets_parsed = 0
  tweets_file.each_line do |tweet|
    # parse tweet to hash form JSON
    tweet = JSON.parse(tweet)

    tweets_parsed += 1
    puts "> [#{Time.now}] #{tweets_parsed} tweets parsed" if tweets_parsed % step == 0

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
            output_error_tweets << tweet
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

    # save tweets in array
    output_tweets << final_tweet
  end

  # close tweets file
  tweets_file.close

  # base name for output and errors
  filename_base = tweets_filename.rpartition('/').last.partition('.').first

  # write errors if any
  unless output_error_tweets.empty?
    output_error = File.open(filename_base + "_error", "w")
    output_error_string = output_error_tweets.map{ |tweet| JSON.generate(tweet) }
    output_error.write(output_error_string.join("\n"))
    output_error.close
  end

  # write tweets if any
  unless output_tweets.empty?
    # open temp file with everything except state and county
    temp_filename = filename_base + "_parsed_temp"
    temp_file = File.open(temp_filename , "w")
    # pass to json each tweet and joins


    output_string = output_tweets.map{ |tweet| JSON.generate(tweet) }
    temp_file.write(output_string.join("\n"))
    temp_file.close

    # execute R script to know state,county for each line
    state_county_filename = 'state_county_temp'
    %x(Rscript lonlat2statecounty.R #{temp_filename} #{state_county_filename})

    # delete temp file
    File.delete(temp_filename)

    # open both files to associate states and couties to tweets
    states_counties = File.open(state_county_filename)

    # open output file
    output_filename = filename_base + "_parsed"
    output_file = File.open(output_filename , "w")
    output_string = ""

    # loop the tweets and the answers to state_county
    output_tweets.each.zip(states_counties.each).each do |tweet, state_county|

      state_county = state_county.chomp.split(',')

      # skips tweet if coordinates are outside shapefile for continental US
      next if state_county.last.empty?

      tweet['coordinates']['state'] = state_county.first
      tweet['coordinates']['county'] = state_county.last

      output_string += JSON.generate(tweet) + "\n"
    end

    output_file.write(output_string)
    output_file.close

    # delete temp file
    File.delete(state_county_filename)
  end

  # print end time
  puts "> [#{Time.now}] ended '#{tweets_filename}' parse"
end

