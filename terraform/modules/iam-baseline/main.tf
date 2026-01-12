# IAM baseline: account password policy + IAM Access Analyzer
# Cost: $0

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length      = 14
  require_uppercase_characters = true
  require_lowercase_characters = true
  require_numbers              = true
  require_symbols              = true

  allow_users_to_change_password = true
  hard_expiry                    = false

  # 90 days age for password 
  max_password_age          = 90
  password_reuse_prevention = 24
}

# IAM Access Analyzer (helps detect unintended external access)
resource "aws_accessanalyzer_analyzer" "account" {
  analyzer_name = "account-access-analyzer"
  type          = "ACCOUNT"
}
