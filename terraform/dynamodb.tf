resource "aws_dynamodb_table" "tasks" {
  name         = "${var.project_name}-tasks"
  billing_mode = "PAY_PER_REQUEST" # On-Demand billing (miễn phí ở mức truy cập thấp)
  hash_key     = "ID"

  attribute {
    name = "ID"
    type = "N" # N đại diện cho Number
  }

  tags = {
    Name        = "${var.project_name}-tasks-table"
    Environment = var.environment
    Project     = var.project_name
  }
}
