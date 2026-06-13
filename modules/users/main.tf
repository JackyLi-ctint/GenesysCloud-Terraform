terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

resource "genesyscloud_user" "service_user" {
  count = var.create_user ? 1 : 0

  email           = var.user_email
  name            = var.user_name
  password        = var.user_password
  state           = "active"
  department      = var.user_department
  title           = var.user_title
  acd_auto_answer = var.user_acd_auto_answer

  addresses {
    phone_numbers {
      number     = var.user_phone_number
      media_type = "PHONE"
      type       = "MOBILE"
    }
  }

  employer_info {
    official_name = var.user_name
    employee_id   = var.user_employee_id
    employee_type = var.user_employee_type
    date_hire     = var.user_hire_date
  }
}

# Role lookup is optional and only evaluated when user creation plus role assignment is enabled.
data "genesyscloud_auth_role" "employee" {
  count = var.create_user && var.assign_default_userrole ? 1 : 0
  name  = "employee"
}

data "genesyscloud_auth_role" "user" {
  count = var.create_user && var.assign_default_userrole ? 1 : 0
  name  = "User"
}

resource "genesyscloud_user_roles" "service_user_roles" {
  count = var.create_user && var.assign_default_userrole ? 1 : 0

  user_id = genesyscloud_user.service_user[0].id

  roles {
    role_id = data.genesyscloud_auth_role.employee[0].id
  }

  roles {
    role_id = data.genesyscloud_auth_role.user[0].id
  }
}
