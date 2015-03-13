# HappiTweet

Welcome to the HappiTweet research project. In this project we relate twitter messages with location happiness.

## Configuration and Installation

Duplicate the `config.yaml.template` and remove the `template` extension. Fill that file with your configuration, namely: 
* Your AWS setting, such as your access credentials
* Your R configuration, such as your working directory

After setting the configuration, you should:
* Run the `r_config.R` script: `./r_config` or `Rscript r_config.R`
* In case you are using the AWS Parser: install needed gems located in the `Gemfile`

## Parsers

Results from parsing the tweet collection should be place in the `huge-data` folder. Due to their large size they are gitignored.

##### AWS Parser
1. From the root, run `ruby aws/task_splitter.rb` so the tasks are complete. In the *task splitter* you can change the file with the urls to be split and how many chunks that file will be split to. Open `aws/task_splitter.rb` and you'll find these settings
2. When the script ends, multiple instances will be running dealing with your data.
3. Periodically, run `ruby aws/checks_complete.rb` so you known the state of your instances. When all the instances seem complete move on to next step.
4. (UNDER DEVELOPLMENT) When all your instances finish, run `ruby aws/end_tasks.rb` so all the data is tranferred to local machines, as well as stopping the AWS instances. Instances are not deleted as a safety measure.

##### Spark Parser


## Features and Model

## Charts