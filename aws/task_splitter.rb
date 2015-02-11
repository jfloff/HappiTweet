#!/usr/bin/env ruby

# Splits files amongst a specified number of AWS servers.
#
# Starts by splitting the file list in n chunks, with n given by the user.
# Then it creates a zip package for each server, starts a server and ftp files to it.
# Finally it connects to the server and starts the command, closing the connection afterwards.
#
# Must be run from the folder root
#
# Parameters
#
# Constants
#
# Returns
#

require 'open-uri'
require 'aws-sdk'
require 'yaml'
require 'net/ssh' 
require 'net/scp'

chunks = 6
file_list = 'data/file_list.txt'

########################################################################################################################
########################################################################################################################
########################################### NO NEED TO CHANGE ANYTHING BELOW  ##########################################
########################################################################################################################
########################################################################################################################

puts "--== HappiTweet: AWS Task Splitter ==--"

# files to send to each instance, relative to project root
files_to_send = [
  "parsers/dataset_filter.rb",
  "parsers/lonlat2statecounty.R",
  "parsers/Gemfile",
  "parsers/ami_initialization.sh"
]

# config file location
config_filepath = File.join(__dir__, '/../config.yaml')

# check if config exists, otherwise aborts
if !File.exist?(config_filepath)
  puts "Config file not found. Make sure you renamed the template file."
  exit
end

# load config
config = YAML.load_file(config_filepath)

# set aws config
Aws.config = {
  access_key_id: config['aws']['access_key_id'],
  secret_access_key: config['aws']['secret_access_key'],
  region: config['aws']['region'],
  # Needed due to this bug: https://github.com/aws/aws-sdk-core-ruby/issues/93#issuecomment-51494857
  ssl_verify_peer: false
}
# opens AWS connection
ec2 = Aws::EC2::Client.new
puts "[HT] AWS Configured"

private_key = File.open(File.join(__dir__, "/../data/#{config['aws']['instance']['key_name']}.pem"), "rb").read
puts "[HT] Private key loaded"

# cleans temp directory
%x{rm temp/*}
puts "[HT] 'temp/' directory cleaned"

# count number of lines of a file
total_lines = %x{wc -l #{file_list}}.split.first.to_f
# splits on the upper bound last one has fewer
lines_to_split = (total_lines / chunks).ceil
# splits file by lines to split and returns all files created
prefix = 'temp/' + File.basename(file_list, ".*") + '_'
# creates new ones with split
%x{split -l #{lines_to_split} #{file_list} #{prefix}}
puts "[HT] File list splitted"

# files created
files_created = Dir[prefix + '*']

puts "[HT] Launching instances ..."
run_instances = ec2.run_instances(
  # required
  image_id: config['aws']['instance']['image_id'],
  # required
  min_count: 1,
  # required
  max_count: chunks,
  key_name: config['aws']['instance']['key_name'],
  instance_type: config['aws']['instance']['instance_type'],
)
puts "[HT] Instances launched"

instance_ids_array = Array.new
i = 0
run_instances.instances.each do |instance|

  instance_id = instance.instance_id
  instance_ids_array << instance_id
  instance_filelist = File.basename files_created[i]

  puts "[HT]   --- Instance #{instance_id} ---"

  # sleeps while instance status is not ready
  puts "[HT]     Waiting for instance to be ready ..."
  loop do 
    sleep(10)
    describe_instance = ec2.describe_instance_status(instance_ids: [instance_id])
    # instance_status = describe_instance.reservations[0].instances[0].state.code
    status = describe_instance.instance_statuses[0]
    if !status.nil?
      if (status.system_status.status == 'ok' and status.instance_status.status == 'ok')
        break
      end
    end
  end
  puts "[HT]     Instance ready"

  public_ip_address = ec2.describe_instances(instance_ids: [instance_id]).reservations[0].instances[0].public_ip_address

  # after its ready, we gonna send the files
  puts "[HT]     Sending files to instance ..."
  Net::SCP.start(public_ip_address, "ubuntu", :key_data => [private_key]) do |scp|
    files_to_send.each do |filepath|
      filepath = File.join(__dir__, '..', filepath) 
      scp.upload!(filepath, "/home/ubuntu/#{File.basename filepath}")
    end

    # send i-th file
    scp.upload!(files_created[i], "/home/ubuntu/#{instance_filelist}")
  end
  puts "[HT]     Files sent"

  # when the files are uploaded we run the sequence
  Net::SSH.start(public_ip_address, "ubuntu", :key_data => [private_key]) do |ssh|
    puts "[HT]     Executing initialization script ..."
    ssh.exec!("bash ami_initialization.sh -l")
    puts "[HT]     Initialization script finished"

    # explained here: http://stackoverflow.com/q/6854055/1700053
    ssh.exec("bash -cl 'nohup ruby dataset_filter.rb file_list_aa > dataset_filter.out &'")
    puts "[HT]     Instance working on tasks..."

    # its necessary to force close the connection
    ssh.shutdown!
  end
  
  # iteration variables
  i += 1
  puts "[HT]   ----------------------------"
end

# add tags to isntances
ec2.create_tags(
  resources: instance_ids_array,
  tags: [
    {
      key: config['aws']['instance']['key'],
      value: config['aws']['instance']['value']
    }
  ]
)
puts "[HT] Tags added to instances"

puts "[HT] Tasks splitted!"