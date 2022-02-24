resource "aws_kinesis_firehose_delivery_stream" "kinesis" {
  //A name to identify the stream
  name = "${terraform.workspace}_kinesis_firehose_test"

  //This is the destination to where the data is delivered
  // This is the destination to where the data is delivered. The only options are s3 (Deprecated, use extended_s3 instead), 
  // extended_s3, redshift, elasticsearch, splunk, and http_endpoint.
  destination = var.firehose_destination

  kinesis_source_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    kinesis_stream_arn = var.kinesis_topic_name_arn
  }

  extended_s3_configuration {
    //The ARN of the AWS credentials.
    role_arn = aws_iam_role.firehose_role.arn

    //The ARN of the S3 bucket
    bucket_arn = var.s3_bucket_arn

    //Buffer incoming data to the specified size, in MBs, before delivering it to the destination.
    buffer_size = var.firehose_buffer_size

    //Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination.
    buffer_interval = var.firehose_buffer_interval

    //The compression format in which file will be saved at destination
    // The compression format. If no value is specified, the default is UNCOMPRESSED. 
    // Other supported values are GZIP, ZIP & Snappy. If the destination is redshift you cannot use ZIP or Snappy.
    compression_format = var.firehose_compression_format

    // custom prefix for S3 subfolders
    // https://aws.amazon.com/blogs/big-data/amazon-kinesis-data-firehose-custom-prefixes-for-amazon-s3-objects/
    prefix = "fhbase/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "fherroroutputbase/!{firehose:random-string}/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"
    data_format_conversion_configuration {
      enabled = false
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          orc_ser_de {}
        }
      }
      schema_configuration {
        region        = var.region
        role_arn      = aws_iam_role.firehose_role.arn
        database_name = aws_glue_catalog_database.kinesis_firehose_database.name        
        table_name    = aws_glue_catalog_table.firehose_table.name
      }
    }

    // Configuration for cloudwatch logging
    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }


  }


}


resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesis/firehose/firehose_log_group"
  retention_in_days = 5
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "FirehoseLogStream"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}


# Glue schema for firehose data conversion
resource "aws_glue_catalog_database" "kinesis_firehose_database" {
  name = "${terraform.workspace}_kinesis_firehose_test"
}


resource "aws_glue_catalog_table" "firehose_table" {
  name          = "firehose_table"
  database_name = aws_glue_catalog_database.kinesis_firehose_database.name
  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/fhbase"
    input_format  = "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat"

    ser_de_info {
      name                  = "orc-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.orc.OrcSerde"
    }

    columns {
      name    = "id"
      type    = "int"
      comment = "id column"
    }
    columns {
      name    = "name"
      type    = "string"
      comment = "name identiier"
    }
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }
}
