resource "aws_iam_role" "monitoring_access_role" {
  name               = "${var.vpc_info["name"]}_${var.region_details["region"]}_monitoring_access_role"
  path               = "/"
  assume_role_policy = file("./files/monitoring/iam/ec2AssumeRolePolicy.json")
}

resource "aws_iam_policy_attachment" "monitoring_role_policy_attachment" {
  name       = "${var.vpc_info["name"]}_${var.region_details["region"]}_monitoring_role_policy_attachment"
  roles      = ["${aws_iam_role.monitoring_access_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
resource "aws_iam_instance_profile" "monitoring_profile" {
  name = "${var.vpc_info["name"]}_${var.region_details["region"]}_monitoring_profile"
  role = aws_iam_role.monitoring_access_role.name
}

resource "aws_iam_role" "eth_nodes_role" {
  name = "eth_nodes_role"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "eth_nodes_role_ec2_policy" {
  name = "eth_nodes_ec2_tag_policy"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "ec2:DeleteTags",
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "eth_nodes_role_policy_attachment" {
  name       = "eth_nodes_role_policy_attachment"
  roles      = ["${aws_iam_role.eth_nodes_role.name}"]
  policy_arn = aws_iam_policy.eth_nodes_role_ec2_policy.arn
}

resource "aws_iam_instance_profile" "eth_nodes_profile" {
  name = "eth_nodes_profile"
  role = aws_iam_role.eth_nodes_role.name
}
