#!/usr/bin/env ruby
require 'open-uri'
require 'net/ssh'

private_key = private_key = File.open(File.join(__dir__, "/../data/packt.pem"), "rb").read
ip = "54.72.239.150"

Net::SSH.start(ip, "ubuntu", :key_data => [private_key]) do |ssh|
  puts ssh.exec!("bash -cl 'nohup ruby dataset_filter.rb file_list_aa > dataset_filter.out &'")
  ssh.shutdown!
end