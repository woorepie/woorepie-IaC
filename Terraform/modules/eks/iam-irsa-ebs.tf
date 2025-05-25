# data "aws_iam_policy" "ebs_csi" {
#   name = "AmazonEBSCSIDriverPolicy"
# }

# resource "aws_iam_role" "ebs_irsa" {
#   name = var.ebs_irsa_iam_role_name

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = var.oidc_provider_arn
#         },
#         Action = "sts:AssumeRoleWithWebIdentity",
#         Condition = {
#           StringEquals = {
#             "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.ebs_irsa_namespace}:${var.ebs_irsa_serviceaccount_name}"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ebs_attach" {
#   role       = aws_iam_role.ebs_irsa.name
#   policy_arn = data.aws_iam_policy.ebs_csi.arn
# }
