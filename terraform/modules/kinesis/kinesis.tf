resource "aws_kinesis_stream" "preprocessing" {
  name            = "${var.name_prefix}-preprocessing"
  shard_count     = var.preprocessing_shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = {
    Name = "${var.name_prefix}-preprocessing"
  }
}

resource "aws_kinesis_stream" "processing" {
  for_each        = var.processing_stream_settings
  name            = "${var.name_prefix}-${each.value.base_name}"
  shard_count     = each.value.shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  shard_level_metrics = var.enable_shard_metrics ? [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded"
  ] : []

  tags = {
    Name = "${var.name_prefix}-processing"
  }
}

resource "aws_kinesis_stream" "vulnerability_processing" {
  name            = "${var.name_prefix}-vulnerability-processing"
  shard_count     = var.vulnerability_processing_shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = {
    Name = "${var.name_prefix}-vulnerability-processing"
  }
}

resource "aws_kinesis_stream" "timestream" {
  name            = "${var.name_prefix}-timestream"
  shard_count     = var.timestream_shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  tags = {
    Name = "${var.name_prefix}-timestream"
  }
}

resource "aws_kinesis_stream" "rules_execution" {
  name            = "${var.name_prefix}-rules_execution"
  shard_count     = var.rules_execution_shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  shard_level_metrics = var.enable_shard_metrics ? [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded"
  ] : []

  tags = {
    Name = "${var.name_prefix}-rules_execution"
  }
}

output "preprocessing_kinesis_stream" {
  value = aws_kinesis_stream.preprocessing
}

output "processing_kinesis_streams" {
  value = {
    for key, value in aws_kinesis_stream.processing : key => merge(
      value,
      {
        parallelization_factor = var.processing_stream_settings[key].parallelization_factor
      }
    )
  }
}

output "encoded_processing_stream_settings" {
  value = jsonencode(
    [
      for stream in values(var.processing_stream_settings) : {
        streamId = stream.stream_id
        baseName = stream.base_name
      }
    ]
  )
}

output "timestream_kinesis_stream" {
  value = aws_kinesis_stream.timestream
}

output "vulnerability_processing_kinesis_stream" {
  value = aws_kinesis_stream.vulnerability_processing
}

output "rules_execution_kinesis_stream" {
  value = aws_kinesis_stream.rules_execution
}
