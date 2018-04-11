# jack-rabbit-ruby
RabbitMQ Log Intercept for hooking relays before writing to DynamoDB - (c) Visibility

##  Pub/Sub

Uses the service available in RabbitMQ server, using topic methodology. Messages come here for persistency in a contracted JSON encoded format between the Node gateway socket service. Those messages are subsequently written to a global DynamoDB instance.

Visibility service and AWS service constants are defined at the top in an attempt at the future junior dev tasked with dismantling my grand masterpiece with one nervous error.

This is part of the continued fragmentation of services to isolate out components of the stack that will eventually experience enormous load and have to be replaced with more optimized constituent services. Long live Rabbit MQ.

## Authentication

Requires to have set up a ~/.aws/credentials file containg format:

```
[default]
aws_access_key = <>
aws_secret_access_key = <>
```

and to have set environment variables:

```
export AWS_ACCESS_KEY_ID=<>
export AWS_SECRET_ACCESS_KEY=<>
export AWS_DEFAULT_REGION=us-west-1
```

** Do not try and override using client params in code, I found that this did not work; the SDK API query will always return `IncompleteSignature` or `SignatureRequired`.

## DynamoDB

Requires a table to be defined before hand. In this case `SessionLogsOsiris` with a primary key `SessionID` and a primary sort key `CreatedAt` used to order the table. This should be some common timeformat down the milliseconds. For now, I am just writing a random string to it. 

