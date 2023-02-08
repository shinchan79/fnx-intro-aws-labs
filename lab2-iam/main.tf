module "iam_group_with_policies" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "superadmins"

  group_users = [
    "${module.iam_user.iam_user_name}"
  ]

  attach_iam_self_management_policy = true

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}

module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"

  name          = "user1"
  force_destroy = true

  password_reset_required = false
}

