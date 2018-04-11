#!/usr/bin/env ruby

# https://github.com/ruby-amqp/bunny
require 'bunny'
require 'aws-sdk'
require 'aws-sdk-dynamodb'
# require 'Date'

# Good Ruby DynamoDB resource: https://gist.github.com/ujuettner/3914147

## NOTE: It seems that AWS prefers to use and only use a combination of ~/.aws/credentials and
## NOTE: environment variables with the credentials for access key, secret, AND region
## NOTE: trying to override using aws-sdk ruby seems to improperly override the params
## NOTE: causing a signature failure response from AWS 
# 3rd party service configurations, aside from in memory/environment auth credentials
# ensure that keys are stored in ~/.aws/credentials as
# [default]
# aws_access_key_id = <>
# aws_secret_access_key = <>
# $DYNAMO_PUBLIC_KEY = ""
# $DYNAMO_PRIVATE_KEY = ""
# module Visibility_DataStore
#   module Visibility_DynamoDB
#     US_WEST_1 = "us-west-1"
#     #
#     # CONFIG Initialize the Aws Config environment
#     # Set up the AWS environment based on a config file
#     #
#     def self.Configure(credentialsDir = File.expand_path("..", Dir.pwd), keyFile = 'dynamoboysprivatekey1.txt')
#       keys_file = File.join(credentialsDir, keyFile)
#       puts "[Visibility_DataStore::Visibility_DynamoDB] Looking for AWS credentials: " + keys_file
#       unless File.exist?(keys_file)
#         puts "#{keys_file} dne"
#         exit 1
#       end
#
#       line_number = 0
#       File.open(keys_file, 'r') do |f|
#         f.each_line do |line|
#           case line_number
#           when 0
#             $DYNAMO_PRIVATE_KEY = line
#           when 1
#             $DYNAMO_PUBLIC_KEY = line
#           end
#           line_number += 1
#         end
#       end
#     end
#     #
#     # CONFIG Initialize the Aws Config environment
#     # Set up the AWS environment based on a config file
#     #
#   end

  module Visibility_RabbitMQ
    ADDRESS_LOOPBACK = "localhost"
    ROOT_LOGGING_CHANNEL = "lc"
    ROOT_ROUTING_KEY = "root.routing.key"
  end
end


Visibility_DataStore::Visibility_DynamoDB.Configure()
# AWS_credentials = Aws::Credentials.new($DYNAMO_PUBLIC_KEY, $DYNAMO_PRIVATE_KEY)
$dynamodb = 0;
class DynamoDB_Resource
    def initialize
      #
      # Global dynamodb
      # Points to US_WEST_1 which has a sort key
      # WARN: RUNS ON SCRIPT EVAL
      $dynamodb = Aws::DynamoDB::Client.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
      puts "DynamoDB booting from " + Visibility_DataStore::Visibility_DynamoDB::US_WEST_1

      dynamoDB_ResourceCheck = Aws::DynamoDB::Resource.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
      dynamoDB_ResourceCheck.tables.each do |table|
        puts "Name:    #{table.name}"
        puts "#Items:  #{table.item_count}"
      end
      #
    end
end
DynamoDB_Resource.new

#
# function store_log(input_session_id, input_log)
#
# @param session_id is a UID device defined string
# @param input_log is an unescaped string of the underlying log message
def store_log(inputSessionID, createdAt, inputLog, deviceSession)
  item = {
    SessionID: inputSessionID,
    CreatedAt: createdAt,
    log: inputLog,
    DeviceSession: deviceSession
  }
  params = {
    table_name: 'SessionLogOsiris',
    item: item
  }
  begin
    result = $dynamodb.put_item(params)
    puts 'Added log'
  rescue  Aws::DynamoDB::Errors::ServiceError => error
    puts 'Unable to add session log:'
    puts error.message
  end
end
#
# function store_log
#

#
# function create_rabbit_mq_listener(channelName=Visibility_DataStore::Visibility_RabbitMQ::ROOT_LOGGING_CHANNEL, routingKey=Visibility_DataStore::Visibility_RabbitMQ::ROOT_ROUTING_KEY)
#
# @param channelName default Visibility_DataStore::Visibility_RabbitMQ::ROOT_LOGGING_CHANNEL for for logging channel default message queue
# @param routingKey default Visibility_DataStore::Visibility_RabbitMQ::ROOT_ROUTING_KEY for
def create_rabbit_mq_listener(channelName=Visibility_DataStore::Visibility_RabbitMQ::ROOT_LOGGING_CHANNEL, routingKey=Visibility_DataStore::Visibility_RabbitMQ::ROOT_ROUTING_KEY)
  # (:host => "localhost", :vhost => "myapp.production", :user => "bunny", :password => "t0ps3kret")
  connection = Bunny.new(:host => Visibility_DataStore::Visibility_RabbitMQ::ADDRESS_LOOPBACK, automatically_recover: false)
  connection.start

  channel = connection.create_channel
  exchange = channel.topic(channelName)
  queue = channel.queue('', exclusive: true)

  queue.bind(exchange, routing_key: routingKey)

  puts ' [*] Waiting for logs on #{channelName}. To exit press CTRL+C'

  begin
    queue.subscribe(block: true) do |delivery_info, _properties, body|
      puts " [x] #{delivery_info.routing_key}:#{body}"
      bodyJSON = JSON.parse(body)
      store_log(bodyJSON["SessionID"], bodyJSON["CreatedAt"], bodyJSON["message"], bodyJSON["DeviceSession"])
    end
  rescue Interrupt => _
    channel.close
    connection.close

    exit(0)
  end
end
#
# function create_rabbit_mq_listener
#

# https://www.rabbitmq.com/tutorials/tutorial-three-ruby.html
