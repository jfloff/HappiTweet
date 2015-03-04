from pyspark import SparkContext
import json
import gzip
import marshal

tweetsFile = "/tmp/ist169518/tweets02*.gz"
outfile = "/tmp/ist169518/out_tweets02"

sc = SparkContext()
sc.addPyFile("/tmp/ist169518/carmen-0.0.3-py2.7.egg")                       
sc.addPyFile("/tmp/ist169518/geopy-1.8.1-py2.7.egg")
import carmen

def carmen_initializer(partition):
    print "\nPartition\n"
    resolver = carmen.get_resolver()
    resolver.load_locations()
    for line in partition:
        yield carmenizer(line, resolver)


def carmenizer(line, resolver):
    tweet = json.loads(line)
    location = None
    try:
        location = resolver.resolve_tweet(tweet)
    except Exception, e:
        #print e
        pass
    if location is not None:
        tweet['carmen'] = dict()
        tweet['carmen']['country'] = location[1].country
        tweet['carmen']['state'] = location[1].state
        tweet['carmen']['county'] = location[1].county
        tweet['carmen']['city'] = location[1].city
        tweet['carmen']['latitude'] = location[1].latitude
        tweet['carmen']['longitude'] = location[1].longitude
        tweet['carmen']['res_method'] = location[1].resolution_method
    return json.dumps(tweet)



thefile = sc.textFile(tweetsFile).mapPartitions(carmen_initializer).saveAsTextFile(outfile)


sc.stop()

