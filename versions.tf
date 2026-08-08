terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }

  # State is left unconfigured on purpose. Local state is fine for learning and
  # for the examples in this repo; anything shared belongs in S3 with DynamoDB
  # locking. docs/REMOTE-STATE.md has a backend block ready to uncomment.
}
