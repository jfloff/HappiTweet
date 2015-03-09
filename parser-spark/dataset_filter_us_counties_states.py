from pyspark import SparkContext
import json
import gzip
import marshal

''' Configuration Parameters '''
tweetsFile = "/tmp/ist169518/out_*/part*"
outFile = "/tmp/ist169518/out-us-simple-counties-states/"

'''Auxiliar Functions Definiton'''

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


def process_tweets(line):
    tweet = json.loads(line)
    tweet = filtered(tweet)
    return json.dumps(tweet)


def filtered(tweet):
    filtered_tweet = dict()
    filtered_tweet['state'] = tweet['carmen']['state']
    filtered_tweet['county'] = tweet['carmen']['county']
    return filtered_tweet



'''Spark Code'''
sc = SparkContext()
thefile = sc.textFile(tweetsFile).filter(from_usa_and_required_fields).map(process_tweets).saveAsTextFile(outFile)
sc.stop()



