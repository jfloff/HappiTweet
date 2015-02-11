# HappiTweet

Welcome to the HappiTweet research project. In this project we relate twitter messages with location happiness.


### Run

1. Fill out `config.yaml` file with your configurations, specially your AWS credentials. Use `config.yaml.template` file as a base.
2. From the root, run `ruby aws/task_splitter.rb` so the tasks are complete. In the *task splitter* you can change the file with the urls to be split and how many chunks that file will be split to. Open `aws/task_splitter.rb` and you'll find these settings
3. When the script ends, multiple instances will be running dealing with your data.
4. Periodically, run `ruby aws/checks_complete.rb` so you known the state of your instances. When all the instances seem complete move on to next step.

UNDER DEVELOPLMENT

5. When all your instances finish, run `ruby aws/end_tasks.rb` so all the data is tranferred to local machines, as well as stopping the AWS instances. Instances are not deleted as a safety measure.
