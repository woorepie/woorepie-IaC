# resource "aws_iam_role" "alb_controller_irsa" {
#   name = var.alb_irsa_iam_role_name

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
#             "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.alb_namespace}:${var.alb_serviceaccount_name}"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
#   role       = aws_iam_role.alb_controller_irsa.name
#   policy_arn = var.alb_irsa_policy_arn
# }
