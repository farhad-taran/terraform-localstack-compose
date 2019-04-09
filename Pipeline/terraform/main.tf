provider "aws" {
    version = "2.4.0"
    region = "eu-west-1"
    access_key = "anaccesskey"
    secret_key = "asecretkey"
    skip_credentials_validation = true
    skip_requesting_account_id = true 
    skip_metadata_api_check = true
    s3_force_path_style = true
    endpoints {
        dynamodb  = "http://localstack:4569"
        s3  = "http://localstack:4572"
        sns = "http://localstack:4575"
        sqs = "http://localstack:4576"
  }
}

resource "aws_sqs_queue" "queue" {
  name      =   "pim-product-s3-event-notification-queue"
  policy    =   <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[
          {
              "Effect" : "Allow",
              "Principal":"*",
              "Action":"sqs:SendMessage",
              "Resource":"arn:aws:sqs:*:*:pim-product-s3-event-notification-queue",
              "Condition":{
                  "ArnEquals":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
              }
          }
      ]      
  }
  POLICY
}

resource "aws_s3_bucket" "bucket" {
  bucket    =   "pim-product-items"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  #count     =   "${var.event ? 1 :  0}"
  bucket    =   "${aws_s3_bucket.bucket.id}"

  queue {
      queue_arn =   "${aws_sqs_queue.queue.arn}"
      events    =   ["s3:ObjectCreated:Put"]
  }
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "pricing"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "EntityKey"
  range_key      = "SortKeyId"

  attribute {
    name = "EntityKey"
    type = "S"
  }

  attribute {
    name = "SortKeyId"
    type = "S"
  }

  tags = {
    Name        = "pricing"
    Environment = "local"
  }
}