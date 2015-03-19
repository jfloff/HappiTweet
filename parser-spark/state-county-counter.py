from pyspark import SparkContext
import json
import gzip
import marshal

''' Configuration Parameters '''

inFile = "hdfs://meninx:8020/tmp/ist169518/us_state_county"

outFileStates = "/tmp/ist169518/out_state"
outFileCounties = "/tmp/ist169518/out_counties"


sc = SparkContext()


def uniformer_county(line):
    tweet = json.loads(line)
    return ("\"" + tweet['state'] + "," +  tweet['county'] +  "\""  , 1)


def uniformer_state(line):
    tweet = json.loads(line)
    return ("\"" + tweet['state'] + "\"", 1)

def to_line(pair):
    return str(pair[0]) + "," + str(pair[1])




sc.textFile(inFile).map(uniformer_state).reduceByKey(lambda a, b: a + b).map(to_line).saveAsTextFile(outFileStates)
sc.textFile(inFile).map(uniformer_county).reduceByKey(lambda a, b: a + b).map(to_line).saveAsTextFile(outFileCounties)


sc.stop()