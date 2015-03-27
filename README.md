# HappiTweet

Welcome to the HappiTweet research project. In this project we relate twitter messages with location happiness.

## Configuration and Installation

Duplicate the `config.yaml.template` and remove the `template` extension. Fill that file with your configuration, namely:
* Your AWS setting, such as your access credentials
* Your R configuration, such as your working directory and needed packages

After setting the configuration, you should:
* Run `source happitweet_config.sh` to perform general configurations
* In case you are using the AWS Parser: install needed gems located in the `Gemfile`

Warning: in some cases you need to restart RStudio (or the terminal if that's the case) after this changes.

## Parsers

Results from parsing the tweet collection should be place in the `huge-data` folder. Due to their large size they are gitignored.

##### AWS Parser
1. From the root, run `ruby aws/task_splitter.rb` so the tasks are complete. In the *task splitter* you can change the file with the urls to be split and how many chunks that file will be split to. Open `aws/task_splitter.rb` and you'll find these settings
2. When the script ends, multiple instances will be running dealing with your data.
3. Periodically, run `ruby aws/checks_complete.rb` so you known the state of your instances. When all the instances seem complete move on to next step.
4. (UNDER DEVELOPLMENT) When all your instances finish, run `ruby aws/end_tasks.rb` so all the data is transferred to local machines, as well as stopping the AWS instances. Instances are not deleted as a safety measure.

##### Spark Parser


## Features and Model

First you need to process the features for your dataset. Edit the files needed in the `feature.R` file:

* `scored_tweets`: file with tweets that have a score associated. Each record should be in a separate line, and each line should have a json record like in the below example:
```json
	{
	  "county":"Conway County",
	  "state":"Arkansas",
	  "scores":[
	    {
	      "en.hedo-happiness-delta_one_of_5":{
	        "score":"8.41",
	        "word_count":1
	      }
	    },
	    {
	      "en.hedo-happiness-more_than_7":{
	        "score":"8.41",
	        "word_count":1
	      }
	    }
	  ]
	}
```

* `all_tweets`: file with all the geolocated tweets of the dataset (regardless if they got a score from any lexicon). Each record should be in a separate line, and each line should have a json record like in the below example:
```json
	{
	  "county":"Conway County",
	  "state":"Arkansas"
	}
```

* `output_state`: CSV with the output of the calculated features for each US state

* `output_county`: CSV with the output of the calculated features for each US county

With the output files from the features, we ran the models for both state and county.


## Charts
