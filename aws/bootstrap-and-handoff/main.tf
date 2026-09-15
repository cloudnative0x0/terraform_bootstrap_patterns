resource "aws_s3_bucket" "state_global" {
  provider = aws.global
  bucket   = "${var.name_prefix}-tfstate-${local.scope_names["global"]}-${var.account_ids["global"]}"

  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.state_global.arn,
        "${aws_s3_bucket.state_global.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_global" {
  provider = aws.global
  bucket   = aws_s3_bucket.state_global.id

  depends_on = [aws_s3_bucket_versioning.state_global]

  rule {
    id     = "state-retention"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_iam_openid_connect_provider" "github_global" {
  provider = aws.global
  url      = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "terraform_runner_global" {
  provider = aws.global
  name     = "tf-${local.scope_names["global"]}-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_global.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = local.external_subject_ids["global"] }
      }
    }]
  })

  max_session_duration = 3600
}

resource "aws_iam_role" "terraform_state_global" {
  provider = aws.global
  name     = "tf-state-manager-${local.scope_names["global"]}"

  depends_on = [aws_iam_role.terraform_runner_global]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_ids["global"]}:role/tf-${local.scope_names["global"]}-runner" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state_global" {
  provider = aws.global
  name     = "terraform-state"
  role     = aws_iam_role.terraform_state_global.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.state_global.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.state_global.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.state_global.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "runner_assume_state_global" {
  provider = aws.global
  name     = "assume-terraform-state-role"
  role     = aws_iam_role.terraform_runner_global.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_state_global.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_global" {
  provider   = aws.global
  for_each   = var.runner_managed_policy_arns["global"]
  role       = aws_iam_role.terraform_runner_global.name
  policy_arn = each.value
}

resource "aws_s3_bucket" "state_core_dev" {
  provider = aws.core_dev
  bucket   = "${var.name_prefix}-tfstate-${local.scope_names["core_dev"]}-${var.account_ids["core_dev"]}"

  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.state_core_dev.arn,
        "${aws_s3_bucket.state_core_dev.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_core_dev" {
  provider = aws.core_dev
  bucket   = aws_s3_bucket.state_core_dev.id

  depends_on = [aws_s3_bucket_versioning.state_core_dev]

  rule {
    id     = "state-retention"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_iam_openid_connect_provider" "github_core_dev" {
  provider = aws.core_dev
  url      = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "terraform_runner_core_dev" {
  provider = aws.core_dev
  name     = "tf-${local.scope_names["core_dev"]}-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_core_dev.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = local.external_subject_ids["core_dev"] }
      }
    }]
  })

  max_session_duration = 3600
}

resource "aws_iam_role" "terraform_state_core_dev" {
  provider = aws.core_dev
  name     = "tf-state-manager-${local.scope_names["core_dev"]}"

  depends_on = [aws_iam_role.terraform_runner_core_dev]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_ids["core_dev"]}:role/tf-${local.scope_names["core_dev"]}-runner" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state_core_dev" {
  provider = aws.core_dev
  name     = "terraform-state"
  role     = aws_iam_role.terraform_state_core_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.state_core_dev.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.state_core_dev.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.state_core_dev.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "runner_assume_state_core_dev" {
  provider = aws.core_dev
  name     = "assume-terraform-state-role"
  role     = aws_iam_role.terraform_runner_core_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_state_core_dev.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_core_dev" {
  provider   = aws.core_dev
  for_each   = var.runner_managed_policy_arns["core_dev"]
  role       = aws_iam_role.terraform_runner_core_dev.name
  policy_arn = each.value
}

resource "aws_s3_bucket" "state_core_prod" {
  provider = aws.core_prod
  bucket   = "${var.name_prefix}-tfstate-${local.scope_names["core_prod"]}-${var.account_ids["core_prod"]}"

  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.state_core_prod.arn,
        "${aws_s3_bucket.state_core_prod.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_core_prod" {
  provider = aws.core_prod
  bucket   = aws_s3_bucket.state_core_prod.id

  depends_on = [aws_s3_bucket_versioning.state_core_prod]

  rule {
    id     = "state-retention"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_iam_openid_connect_provider" "github_core_prod" {
  provider = aws.core_prod
  url      = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "terraform_runner_core_prod" {
  provider = aws.core_prod
  name     = "tf-${local.scope_names["core_prod"]}-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_core_prod.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = local.external_subject_ids["core_prod"] }
      }
    }]
  })

  max_session_duration = 3600
}

resource "aws_iam_role" "terraform_state_core_prod" {
  provider = aws.core_prod
  name     = "tf-state-manager-${local.scope_names["core_prod"]}"

  depends_on = [aws_iam_role.terraform_runner_core_prod]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_ids["core_prod"]}:role/tf-${local.scope_names["core_prod"]}-runner" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state_core_prod" {
  provider = aws.core_prod
  name     = "terraform-state"
  role     = aws_iam_role.terraform_state_core_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.state_core_prod.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.state_core_prod.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.state_core_prod.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "runner_assume_state_core_prod" {
  provider = aws.core_prod
  name     = "assume-terraform-state-role"
  role     = aws_iam_role.terraform_runner_core_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_state_core_prod.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_core_prod" {
  provider   = aws.core_prod
  for_each   = var.runner_managed_policy_arns["core_prod"]
  role       = aws_iam_role.terraform_runner_core_prod.name
  policy_arn = each.value
}

resource "aws_s3_bucket" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = "${var.name_prefix}-tfstate-${local.scope_names["shared_network_dev"]}-${var.account_ids["shared_network_dev"]}"

  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.state_shared_network_dev.arn,
        "${aws_s3_bucket.state_shared_network_dev.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_shared_network_dev" {
  provider = aws.shared_network_dev
  bucket   = aws_s3_bucket.state_shared_network_dev.id

  depends_on = [aws_s3_bucket_versioning.state_shared_network_dev]

  rule {
    id     = "state-retention"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_iam_openid_connect_provider" "github_shared_network_dev" {
  provider = aws.shared_network_dev
  url      = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "terraform_runner_shared_network_dev" {
  provider = aws.shared_network_dev
  name     = "tf-${local.scope_names["shared_network_dev"]}-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_shared_network_dev.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = local.external_subject_ids["shared_network_dev"] }
      }
    }]
  })

  max_session_duration = 3600
}

resource "aws_iam_role" "terraform_state_shared_network_dev" {
  provider = aws.shared_network_dev
  name     = "tf-state-manager-${local.scope_names["shared_network_dev"]}"

  depends_on = [aws_iam_role.terraform_runner_shared_network_dev]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_ids["shared_network_dev"]}:role/tf-${local.scope_names["shared_network_dev"]}-runner" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state_shared_network_dev" {
  provider = aws.shared_network_dev
  name     = "terraform-state"
  role     = aws_iam_role.terraform_state_shared_network_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.state_shared_network_dev.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.state_shared_network_dev.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.state_shared_network_dev.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "runner_assume_state_shared_network_dev" {
  provider = aws.shared_network_dev
  name     = "assume-terraform-state-role"
  role     = aws_iam_role.terraform_runner_shared_network_dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_state_shared_network_dev.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_shared_network_dev" {
  provider   = aws.shared_network_dev
  for_each   = var.runner_managed_policy_arns["shared_network_dev"]
  role       = aws_iam_role.terraform_runner_shared_network_dev.name
  policy_arn = each.value
}

resource "aws_s3_bucket" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = "${var.name_prefix}-tfstate-${local.scope_names["shared_network_prod"]}-${var.account_ids["shared_network_prod"]}"

  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_public_access_block" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.state_shared_network_prod.arn,
        "${aws_s3_bucket.state_shared_network_prod.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "state_shared_network_prod" {
  provider = aws.shared_network_prod
  bucket   = aws_s3_bucket.state_shared_network_prod.id

  depends_on = [aws_s3_bucket_versioning.state_shared_network_prod]

  rule {
    id     = "state-retention"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

resource "aws_iam_openid_connect_provider" "github_shared_network_prod" {
  provider = aws.shared_network_prod
  url      = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "terraform_runner_shared_network_prod" {
  provider = aws.shared_network_prod
  name     = "tf-${local.scope_names["shared_network_prod"]}-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github_shared_network_prod.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = local.external_subject_ids["shared_network_prod"] }
      }
    }]
  })

  max_session_duration = 3600
}

resource "aws_iam_role" "terraform_state_shared_network_prod" {
  provider = aws.shared_network_prod
  name     = "tf-state-manager-${local.scope_names["shared_network_prod"]}"

  depends_on = [aws_iam_role.terraform_runner_shared_network_prod]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_ids["shared_network_prod"]}:role/tf-${local.scope_names["shared_network_prod"]}-runner" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform_state_shared_network_prod" {
  provider = aws.shared_network_prod
  name     = "terraform-state"
  role     = aws_iam_role.terraform_state_shared_network_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.state_shared_network_prod.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.state_shared_network_prod.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${aws_s3_bucket.state_shared_network_prod.arn}/*.tflock"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "runner_assume_state_shared_network_prod" {
  provider = aws.shared_network_prod
  name     = "assume-terraform-state-role"
  role     = aws_iam_role.terraform_runner_shared_network_prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_state_shared_network_prod.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "runner_shared_network_prod" {
  provider   = aws.shared_network_prod
  for_each   = var.runner_managed_policy_arns["shared_network_prod"]
  role       = aws_iam_role.terraform_runner_shared_network_prod.name
  policy_arn = each.value
}

