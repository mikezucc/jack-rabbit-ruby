# 3rd party service configurations, aside from in memory/environment auth credentials
# ensure that keys are stored in ~/.aws/credentials as
# [default]
# aws_access_key_id = <>
# aws_secret_access_key = <>
# $DYNAMO_PUBLIC_KEY = ""
# $DYNAMO_PRIVATE_KEY = ""
module Visibility_DataStore
  module Visibility_DynamoDB
    US_WEST_1 = "us-west-1"
    TABLE_SESSIONS_OSIRIS = "SessionsOsiris"
    TABLE_SESSION_LOGS_OSIRIS = "SessionsLogsOsiris"
    ## NOTE: It seems that AWS prefers to use and only use a combination of ~/.aws/credentials and
    ## NOTE: environment variables with the credentials for access key, secret, AND region
    ## NOTE: trying to override using aws-sdk ruby seems to improperly override the params
    ## NOTE: causing a signature failure response from AWS
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
  end

  module Visibility_RabbitMQ
    ADDRESS_LOOPBACK = "localhost"
    ROOT_LOGGING_CHANNEL = "lc"
    ROOT_ROUTING_KEY = "root.routing.key"
  end
end
