# resource "kubernetes_service_account" "alb_controller" {
#   metadata {
#     # name      = var.alb_serviceaccount_name
#     # namespace = var.alb_namespace
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_irsa.arn
#     }
#   }
# }
