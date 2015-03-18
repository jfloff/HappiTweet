#!/usr/bin/env ruby

# Checks if each instance has finished
#
# Starts by splitting the file list in n chunks, with n given by the user.
# Then it creates a zip package for each server, starts a server and ftp files to it.
# Finally it connects to the server and starts the command, closing the connection afterwards.

require 'open-uri'
require 'aws-sdk'
require 'yaml'
require 'net/ssh' 
require 'net/scp'

########################################################################################################################
########################################################################################################################
########################################### NO NEED TO CHANGE ANYTHING BELOW  ##########################################
########################################################################################################################
########################################################################################################################

puts "--== HappiTweet: End AWS tasks ==--"

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

# filter EC2 by HappiTweet tag
describe_instances = ec2.describe_instances(
  filters: [
    # filter only instances tagged with the defined key/value
    {
      name: 'tag:' + config['aws']['instance']['key'],
      values: [config['aws']['instance']['value']]
    },
    # filter only pending or running instances
    {
      name: 'instance-state-code',
      values: ['0','16']
    }
  ]
)

# gets all instance ids from describe instances
ips = Array.new
describe_instances.reservations.each do |reservation|
  reservation.instances.each do |instance|
  	ips << instance.public_ip_address
  end
end

ips.each do |ip|
  puts "[HT]   --- Instance IP: #{ip} ---"
  # download files from machine
  Net::SSH.start(ip, "ubuntu", :key_data => [private_key]) do |ssh|
    
  end
  # stops machine (does not delete as a safety measure)
end
