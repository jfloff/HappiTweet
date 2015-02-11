#!/usr/bin/env ruby

require 'unicode_utils/downcase'
require 'open-uri'
require 'json'
require 'csv'
require 'set'
require 'zlib'

# RELEVANT INFO:

# csv files with first column with the word, and second with the score separated with commans
word_lists_info = [
  {key: 'en.hedo' , path: '../data/hedonometer_anew_full.csv'},
  {key: 'es.anew' , path: '../data/es_anew_all.csv'}
]
# function that filters the words in the list accordingly to some parameter
def word_score_filter(word,score)
  return score > 7
end

########################################################################################################################
########################################################################################################################
########################################### NO NEED TO CHANGE ANYTHING BELOW  ##########################################
########################################################################################################################
########################################################################################################################

# path to file with all tweets passed as argument
tweets_filename = ARGV[0]
# output filename
output_filename = ARGV[1]

# Load word lists
word_lists = []
word_lists_info.each do |word_list_info|
  word_list = Hash.new
  filepath = File.expand_path(word_list_info[:path])
  CSV.foreach(filepath) do |row|
    word = UnicodeUtils.downcase(row[0])
    score = row[1].to_f

    if word_score_filter(word,score)
      word_list[word] = score
    end
  end
  word_lists << {key: word_list_info[:key], word_list: word_list}
end

output_file = File.open(output_filename, "w")
tweets_file = open(tweets_filename)

begin
  tweets_file.each_line do |tweet|
    tweet = JSON.parse(tweet)

    choosen_record = {total_words: 0}
    word_lists.each do |word_list|

      record = {
        word_list: word_list[:word_list],
        word_list_key: word_list[:key],
        words_found: Set.new,
        # init hash always with 0
        total_word_occurences: Hash.new(0),
        total_words: 0
      }

      tweet['text'].split.each do |tweet_word|
        if word_list[:word_list].has_key? tweet_word
          record[:words_found] << tweet_word
          record[:total_word_occurences][tweet_word] += 1
          record[:total_words] += 1
        end
      end

      # replaces record if more words found in the
      choosen_record = record if record[:total_words] > choosen_record[:total_words]
    end

    if choosen_record[:total_words] > 0
      # counts the words and the score for each word
      # sums the total number of words and the total scoe
      total_words = 0
      total_score = 0
      choosen_record[:total_word_occurences].each do |word,count|
        total_words += count
        total_score += choosen_record[:word_list][word] * count
      end

      tweet['score'] = (total_score / total_words).round(2)
      tweet['word_count'] = total_words
      # convert to array for json print
      tweet['words_found'] = choosen_record[:words_found].to_a
      tweet['word_list_key'] = choosen_record[:word_list_key]

      output_file.write(JSON.generate(tweet) + "\n")
    end
  end
ensure
  tweets_file.close
  output_file.close
end
