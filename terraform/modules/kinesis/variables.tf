variable "name_prefix" { type = string }
variable "preprocessing_shard_count" { type = number }
variable "vulnerability_processing_shard_count" { type = number }
variable "timestream_shard_count" { type = number }
variable "enable_shard_metrics" {
  type = bool
}
variable "rules_execution_shard_count" { type = number }
variable "processing_stream_settings" {
  type = map(object({
    base_name              = string
    stream_id              = string
    shard_count            = number
    parallelization_factor = number
  }))
}
