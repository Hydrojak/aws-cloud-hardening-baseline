# V2.1 - Detection sink: CloudWatch Log Group (cost-conscious)

resource "aws_cloudwatch_log_group" "detections" {
  name              = var.log_group_name
  retention_in_days = var.retention_days
}
