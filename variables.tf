################################
##  Input Variables - Global  ##
################################
variable "customer_shortname" {
  description = "A short version of the customer name. Eg. Fortytwo would be ft"
  type        = string
}

variable "env" {
  description = "What environment the resources are deployed in. Eg. p = prod, t = test, d = dev"
  type        = string
}

variable "location" {
  description = "What location the resources should be deployed in. Eg. westeurope, norwayeast"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags."
  default     = null
}


#######################################
##  Input Variables - AVD Workspace  ##
#######################################
variable "avd-workspaces" {
  description = "A list of objects with one object per workspace. See documentation below for values and examples."
  type = list(object({
    name          = string
    location      = string
    friendly_name = string
    tags          = optional(map(string))
  }))
}


####################################
##  Input Variables - Host Pools  ##
####################################
variable "avd-host_pools" {
  description = "A list of objects with one object per host pool. See documentation below for values and examples."
  type = list(object({
    name                             = string
    friendly_name                    = optional(string)
    description                      = optional(string)
    location                         = string
    type                             = optional(string, "Pooled")
    load_balancer_type               = optional(string, "DepthFirst")
    validate_environment             = optional(bool, false)
    start_vm_on_connect              = optional(bool, false)
    custom_rdp_properties            = optional(string)
    personal_desktop_assignment_type = optional(string, "Automatic")
    maximum_sessions_allowed         = optional(number)
    preferred_app_group_type         = optional(string)
    tags                             = optional(map(string))
    scheduled_agent_updates = optional(object({
      enabled                   = optional(bool, false)
      timezone                  = optional(string)
      use_session_host_timezone = optional(bool, true)
      schedule = optional(object({
        day_of_week = string
        hour_of_day = number
      }))
    }))

    registration_expiration_date = string
  }))
}


################################################
##  Input Variables - AVD Application Groups  ##
################################################
variable "avd-application_groups" {
  description = "A list of objects with one object per application group. See documentation below for values and examples."
  type = list(object({
    name                         = string
    friendly_name                = optional(string)
    description                  = optional(string)
    type                         = string
    host_pool_name               = string
    workspace_name               = string
    default_desktop_display_name = optional(string)
    tags                         = optional(map(string))
  }))
  default = []
}


##########################################
##  Input Variables - AVD Applications  ##
##########################################
variable "avd-applications" {
  description = "A list of objects with one object per application. See documentation below for values and examples."
  type = list(object({
    name                         = string
    friendly_name                = optional(string)
    description                  = optional(string)
    application_group_name       = string
    path                         = string
    command_line_argument_policy = string
    command_line_arguments       = optional(string)
    show_in_portal               = optional(bool)
    icon_path                    = optional(string)
    icon_index                   = optional(string)
  }))
  default = []
}


####################################################
##  Input Variables - AVD - Shared Image Gallery  ##
####################################################
variable "avd-shared-image-gallery" {
  description = "An object describing a Shared Image Gallery resource, if it should be deployed."
  type = list(object({
    name                = string
    description         = optional(string)
    tags                = optional(map(string))
  }))
  default = []
}


###########################################
##  Input Variables - AVD Session Hosts  ##
###########################################
variable "avd-session-hosts" {
  description = "A list of objects with one object per session host. See documentation below for values and examples."
  type = list(object({
    name               = string
    session_host_count = number
    admin_username     = string
    admin_password     = string
    size               = string
    timezone           = optional(string)
    source_image_id    = optional(string) # One of either source_image_id or source_image_reference must be set
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    plan = optional(object({
      name      = string
      product   = string
      publisher = string
    }))
    os_disk = object({
      name                 = optional(string)
      caching              = string
      storage_account_type = string
      disk_size_gb         = string
    })
    subnet_id                    = string
    dns_servers                  = optional(list(string))
    platform_update_domain_count = optional(number)
    platform_fault_domain_count  = optional(number)
    tags                         = optional(map(string)) # Map of tags to be set. If omitted, default tags will be applied
    data_disks = optional(list(object({
      name                 = string
      storage_account_type = optional(string, "Standard_LRS")
      disk_size_gb         = number
      lun                  = number
      caching              = optional(string, "None")
    })))
    aadds_domain_name                         = string
    aadds_avd_ou_path                         = string
    azuread_user_dc_admin_upn                 = string
    azuread_user_dc_admin_password            = string
    avd_session_host_registration_modules_url = string
    host_pool_name                            = string
  }))
}


#######################
##  Local Variables  ##
#######################
locals {
  prefix = "${var.customer_shortname}-${var.env}"

  # Use this map with the var.env input variable as input, to translate the env to human readable
  env = {
    p = "Production"
    d = "Development"
    t = "Test"
    q = "QA"
    s = "Staging"
  }

  tags = var.tags == null ? local.default-tags : var.tags
  default-tags = {
    Customer    = var.customer_shortname
    Environment = local.env[var.env]
    Location    = var.location
  }
}
