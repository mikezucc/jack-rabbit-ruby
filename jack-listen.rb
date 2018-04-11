#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new
# (:host => "localhost", :vhost => "myapp.production", :user => "bunny", :password => "t0ps3kret")
connection = Bunny.new(:host => "localhost", automatically_recover: false)
connection.start

channel = connection.create_channel
exchange = channel.topic('lc')
queue = channel.queue('', exclusive: true)

queue.bind(exchange, routing_key: 'anonymous.info')

puts ' [*] Waiting for logs. To exit press CTRL+C'

begin
  queue.subscribe(block: true) do |delivery_info, _properties, body|
    puts " [x] #{delivery_info.routing_key}:#{body}"
  end
rescue Interrupt => _
  channel.close
  connection.close

  exit(0)
end

dynamodb = Aws::DynamoDB::Client.new(region: 'us-west-1')
item = {
    year: 2015,
    title: 'The Big New Movie',
    info: {
        plot: 'Nothing happens at all.',
        rating: 0
    }
}

params = {
    table_name: 'Movie',
    item: item
}

begin
  result = dynamodb.put_item(params)
  puts 'Added movie: ' + year.to_i.to_s + ' - ' + title
rescue  Aws::DynamoDB::Errors::ServiceError => error
  puts 'Unable to add movie:'
  puts error.message
end

# https://www.rabbitmq.com/tutorials/tutorial-three-ruby.html
