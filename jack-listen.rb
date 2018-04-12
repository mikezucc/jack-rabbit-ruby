#!/usr/bin/env ruby

# https://github.com/ruby-amqp/bunny
require 'bunny'
require 'aws-sdk'
require 'aws-sdk-dynamodb'
require './jack-knows.rb'
# require 'Date'

# Good Ruby DynamoDB resource: https://gist.github.com/ujuettner/3914147

# Visibility_DataStore::Visibility_DynamoDB.Configure()
# AWS_credentials = Aws::Credentials.new($DYNAMO_PUBLIC_KEY, $DYNAMO_PRIVATE_KEY)
$dynamodb_WRITE_OSIRIS = 0;
class DynamoDB_Read_Resource
    def initialize
      #
      # Global dynamodb
      # Points to US_WEST_1 which has a sort key
      # WARN: RUNS ON SCRIPT EVAL
      $dynamodb_WRITE_OSIRIS = Aws::DynamoDB::Client.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
      puts "DynamoDB booting from " + Visibility_DataStore::Visibility_DynamoDB::US_WEST_1

      dynamoDB_ResourceCheck = Aws::DynamoDB::Resource.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
      dynamoDB_ResourceCheck.tables.each do |table|
        puts "Name:    #{table.name}"
        puts "#Items:  #{table.item_count}"
      end
    end
end
DynamoDB_Read_Resource.new

#
# function begin_log(measurement)
#
# @param bodyJSON Visibilty Standards 1: Device identifier protocol, info dictionary, json
# NOTE: Epoch measurement here
def begin_log(bodyJSON)
  sinceEpoch = (Time.now.to_f * 100000).to_i
  item = {
    LogID: bodyJSON["LogID"],
    SinceEpoch: sinceEpoch,
    log: bodyJSON["message"],
    DeviceSession: bodyJSON["DeviceSession"],
    DeviceID: bodyJSON["DeviceID"],
    TeamID: bodyJSON["TeamID"],
  }
  params = {
    table_name: Visibility_DataStore::Visibility_DynamoDB::TABLE_SESSIONS_OSIRIS,
    item: item
  }
  begin
    result = $dynamodb_WRITE_OSIRIS.put_item(params)
    puts 'Added log'
  rescue  Aws::DynamoDB::Errors::ServiceError => error
    puts 'Unable to add session log:'
    puts error.message
  end
end
#
# function begin_log(measurement)
#

#
# function store_log(bodyJSON)
#
# @param bodyJSON Visibilty Standards 1: Device identifier protocol, info dictionary, json
# NOTE: Epoch measurement here
def store_log(bodyJSON)
  sinceEpoch = (Time.now.to_f * 100000).to_i
  item = {
    LogID: bodyJSON["LogID"],
    SinceEpoch: sinceEpoch,
    log: bodyJSON["message"],
    DeviceSession: bodyJSON["DeviceSession"],
    DeviceID: bodyJSON["DeviceID"],
    TeamID: bodyJSON["TeamID"],
  }
  params = {
    table_name: Visibility_DataStore::Visibility_DynamoDB::TABLE_SESSION_LOGS_OSIRIS,
    item: item
  }
  begin
    result = $dynamodb_WRITE_OSIRIS.put_item(params)
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
      store_log(bodyJSON)
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
