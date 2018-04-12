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
$dynamodb_READ_OSIRIS = 0;
class DynamoDB_Write_Resource
  def initialize
    #
    # Global dynamodb
    # Points to US_WEST_1 which has a sort key
    # WARN: RUNS ON SCRIPT EVAL
    $dynamodb_READ_OSIRIS = Aws::DynamoDB::Client.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
    puts "DynamoDB booting from " + Visibility_DataStore::Visibility_DynamoDB::US_WEST_1

    dynamoDB_ResourceCheck = Aws::DynamoDB::Resource.new(region: Visibility_DataStore::Visibility_DynamoDB::US_WEST_1)
    dynamoDB_ResourceCheck.tables.each do |table|
      puts "Name:    #{table.name}"
      puts "#Items:  #{table.item_count}"
    end
  end
end
DynamoDB_Write_Resource.new

#
# function query_get_sessions_by_session_id(inputSessionID)
#
# @param session_id is a UID device defined string
# @param input_log is an unescaped string of the underlying log message
def query_get_sessions_by_session_id(inputSessionID)
  params = {
    table_name: Visibility_DataStore::Visibility_DynamoDB::TABLE_SESSIONS_OSIRIS,
    key_condition_expression: "#SessionID = :session_id",
    expression_attribute_names: {
        "#SessionID" => "year"
    },
    expression_attribute_values: {
        ":session_id" => inputSessionID
    }
  }

  puts "Querying for sessions of #{inputSessionID}"

  begin
      result = $dynamodb_READ_OSIRIS.query(params)
      puts "Query succeeded."

      result.items.each do |session|
         puts "#{session["SessionID"].to_i} #{movie["title"]}"
      end

  rescue  Aws::DynamoDB::Errors::ServiceError => error
      puts "Unable to query table:"
      puts "#{error.message}"
  end
end
#a
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
