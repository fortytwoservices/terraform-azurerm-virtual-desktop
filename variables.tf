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
    location      = optional(string)
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
    workspace_name                   = string
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
      schedule = optional(list(object({
        day_of_week = string
        hour_of_day = number
      })))
    }))

    registration_expiration_date = optional(string)
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
    avd-users                    = optional(list(string))
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
    name        = string
    description = optional(string)
    tags        = optional(map(string))
  }))
  default = []
}


#####################
##  AVD - FSLogix  ##
#####################
variable "avd-fslogix" {
  description = "An object describing the storage account and file share for FSLogix"
  type = list(object({
    name                       = string
    account_tier               = optional(string, "Premium")
    account_kind               = optional(string, "StorageV2")
    account_replication_type   = optional(string, "LRS")
    access_tier                = optional(string, "Hot")
    azure_files_authentication = optional(bool, false)
    azure_share_quota          = optional(string, "100")
  }))
  default = []
}


###########################################
##  Input Variables - AVD Session Hosts  ##
###########################################
variable "avd-session-hosts" {
  description = "A list of objects with one object per session host. See documentation below for values and examples."
  type = list(object({
    name               = string                                             # Name of session hosts
    session_host_count = number                                             # Number of session hosts
    admin_username     = string                                             # Local administrator username
    admin_password     = string                                             # Local administrator password
    size               = string                                             # VM Size SKU for the session hosts
    timezone           = optional(string)                                   # Specify timezone for the session hosts
    source_image_id    = optional(string)                                   # One of either source_image_id or source_image_reference must be set
    source_image_reference = optional(object({                              # Source Image Reference
      publisher = string                                                    # Image Publisher
      offer     = string                                                    # Image Offer
      sku       = string                                                    # Image SKU
      version   = string                                                    # Image Version
    }))                                                                     #
    plan = optional(object({                                                # Plan for Microsoft Marketplace image
      name      = string                                                    # Image Name
      product   = string                                                    # Image Product
      publisher = string                                                    # Image Publisher
    }))                                                                     #
    os_disk = object({                                                      # Operating System Disk block
      name                 = optional(string)                               # Name of OS disk
      caching              = string                                         # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"
      storage_account_type = string                                         # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
      disk_size_gb         = optional(string)                               # Size of OS Disk in GigaBytes
    })                                                                      #
    subnet_id                    = string                                   # Subnet ID for the session hosts to be attached to
    dns_servers                  = optional(list(string))                   # Specify DNS servers for the session hosts
    platform_update_domain_count = optional(number)                         # Availability Set Platform Update Domain count
    platform_fault_domain_count  = optional(number)                         # Availability Set Platform Fault Domain count
    tags                         = optional(map(string))                    # Map of tags to be set. If omitted, default tags will be applied
    data_disks = optional(list(object({                                     # Repeatable block for additional data disks
      name                 = string                                         # Name of Data Disk
      storage_account_type = optional(string, "Standard_LRS")               # Storage Account Type for Data Disk
      disk_size_gb         = number                                         # Size of Data Disk in GigaBytes
      lun                  = number                                         # Unique LUN number for Data Disk
      caching              = optional(string, "None")                       # Type of Caching for Data Disk. Possible values are "None", "ReadOnly", "ReadWrite"
    })))                                                                    #
    azure_domain_join_type                    = optional(string, "azuread") # Allowed values are "azuread" and "aadds"
    aadds_domain_name                         = optional(string)            # Name of Azure Active Directory Domain Services to join the session hosts to
    aadds_avd_ou_path                         = optional(string)            # Azure Active Directory Domain Services OU Path
    azuread_user_dc_admin_upn                 = optional(string)            # DC Admin username
    azuread_user_dc_admin_password            = optional(string)            # DC Admin password
    avd_session_host_registration_modules_url = string                      # AVD Session Host registration modules URL
    host_pool_name                            = string                      # Name of Host Pool for the Session Hosts to be joined to
  }))                                                                       #
  default = []
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
