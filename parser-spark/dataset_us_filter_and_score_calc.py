from pyspark import SparkContext
import json
import gzip
import marshal

''' Configuration Parameters '''

tweetsFile = "/tmp/ist169518/out_*/part*"
outFileProcessedDataset = "/tmp/ist169518/filtered-scored"

# Emotional Lexicons
# csv files with first column with the word, and second with the score separated with commas
word_list_info = [
  {'key': 'en.hedo' , 'path': '/Users/manuelreis/Downloads/hedonometer_anew_full.csv' },
  {'key': 'es.anew' , 'path': '/Users/manuelreis/Downloads/es_anew_all.csv'}
]

#The set of considered filters appliable to the lexicons. Note that every enty on this set must have an associated method whose name starts by "score_filter_", e.g., def score_filter_MYFILTER: ...
filters = ['more_than_7', 'delta_one_of_5', 'no_filter']


'''Auxiliar Functions Definiton'''

# functions that filters the words in the list accordingly to some parameter
def score_filter_more_than_7(score):
  return score > 7

def score_filter_delta_one_of_5(score):
    return  score < 4 or score > 6

def score_filter_no_filter(score):
    return True


### DO NOT MODIFY BELOW THIS LINE ###

def process_tweets(line):
    tweet = json.loads(line)
    tweet = filtered(tweet)
    tweet = calculate_emotional_score(tweet)
    if tweet is not None:
        tweet.pop("text", None)
        return json.dumps(tweet)
    else:
        return ""

def calculate_emotional_score(tweet):
    ok_to_output = False
    tweet_words = tweet['text'].lower().split()
    for word_lists_key in word_lists_var.value.keys():
        choosen_record = {'total_words': 0}
        for word_list in word_lists_var.value[word_lists_key]:
            record = {'word_list_key': word_list['key'], 'total_word_occurences': dict(), 'total_words': 0}
            for word in tweet_words:
                score = word_list['word_list'].get(word, None)
                if score is not None:
                    record['total_words'] += 1
                    total_word_occurences = record['total_word_occurences'].get(word, None)
                    if total_word_occurences is None:
                        record['total_word_occurences'][word] = {'occurences': 1 ,'score': score}
                    else:
                        total_word_occurences['occurences'] += 1
            if record['total_words'] > choosen_record['total_words']: choosen_record = record
        if choosen_record['total_words'] > 0:
            ok_to_output = True
            total_score = 0
            for term in choosen_record['total_word_occurences'].values():
                total_score += term['occurences'] * term['score']
            score = format(total_score / choosen_record['total_words'], '.2f')
            tweet['scores'][word_lists_key] = {'score': score, 'word_list_key': choosen_record['word_list_key'], 'word_count': choosen_record['total_words']}

    if ok_to_output:
        return tweet
    else:
        return None
  

def filtered(tweet):
    filtered_tweet = dict()
    filtered_tweet['state'] = tweet['carmen']['state']
    filtered_tweet['county'] = tweet['carmen']['county']
    filtered_tweet['text'] = tweet['text']
    filtered_tweet['scores'] = dict()
    return filtered_tweet

states = ["alabama","arizona","arkansas","california","colorado","connecticut","delaware","florida","georgia","idaho","illinois","indiana","iowa","kansas","kentucky","louisiana","maine","maryland","massachusetts","michigan","minnesota","mississippi","missouri","montana","nebraska","nevada","new hampshire","new jersey","new mexico","new york","north carolina","north dakota","ohio","oklahoma","oregon","pennsylvania","rhode island","south carolina","south dakota","tennessee","texas","utah","vermont","virginia","washington","west virginia","wisconsin","wyoming"]
def from_usa_and_required_fields(line):
    tweet = json.loads(line)
    try:
       if tweet['carmen']['country'] == "United States" and tweet['carmen']['state'] and tweet['carmen']['county'] and tweet['carmen']['state'] != "Alaska" and tweet['carmen']['state'] != "Hawaii" and tweet['carmen']['state'].lower().strip() in states:
           return True
    except Exception, e:
        #print e
        return False
    return False


'''Loading Emotional Lexicons'''

word_lists = dict()
for filter_name in filters:
        word_lists[filter_name] = list()

for info in word_list_info:
    temporary_word_lists = dict()
    for filter_name in filters:
        temporary_word_lists[filter_name] = dict()
    with open(info['path'], "r") as fp:
        for line in fp:
            row = line.split(',')
            word = row[0].lower().decode('utf-8')
            score = float(row[1])
            for filter_name in filters:
                if globals()["score_filter_" + filter_name](score):
                    temporary_word_lists[filter_name][word] = score
    for filter_name in filters:
        word_lists[filter_name].append({'key': info['key'], 'word_list': temporary_word_lists[filter_name]})


'''Spark Code'''
sc = SparkContext()
#broadcast wordlists
word_lists_var = sc.broadcast(word_lists)



#not not line returns true if the line is not an empty string
thefile = sc.textFile(tweetsFile).filter(from_usa_and_required_fields).map(process_tweets).filter(lambda line: not not line).saveAsTextFile(outFileProcessedDataset)
sc.stop()

