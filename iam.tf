# Instance profile to provide the Seafile server with permissions to S3
resource "aws_iam_instance_profile" "instance_profile" {
  name = aws_iam_role.instance_role.name
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name = "ec2-seafile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    Name = local.project_name
  }
}

resource "aws_iam_role_policy" "instance_policy" {
  name = aws_iam_role.instance_role.name
  role = aws_iam_role.instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject",
        "s3:RestoreObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.datastore.arn}",
        "${aws_s3_bucket.datastore.arn}/*"
      ]
    }
  ]
}
EOF
}

