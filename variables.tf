################################
##  Input Variables - Global  ##
################################
variable "shortname" {
  description = "A short version of the customer name. Eg. Fortytwo would be ft"
  type        = string
  default     = null
}

variable "env" {
  description = "What environment the resources are deployed in. Expected values: p, prod, d, dev, t, test, q, qa, s, stage"
  type        = string
}

variable "location" {
  description = "Default location for all resources, unless specified further for any resources. Eg. westeurope, norwayeast"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources. Will be applied to all resources. Sending tags will overwrite the default tags."
  type        = map(string)
  default     = null
}


#######################################
##  Input Variables - AVD Workspace  ##
#######################################
variable "avd-workspaces" {
  description = "A list of objects with one object per workspace. See documentation below for values and examples."
  type = list(object({
    name          = string                # Name of Workspace
    location      = optional(string)      # Specify location of Workspace, if omitted, default location in main inputs will be used
    friendly_name = string                # Pretty friendly name to be displayed
    tags          = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
  }))
}


####################################
##  Input Variables - Host Pools  ##
####################################
variable "avd-host_pools" {
  description = "A list of objects with one object per host pool. See documentation below for values and examples."
  type = list(object({
    name                             = string                         # Name of Host Pool
    friendly_name                    = optional(string)               # Pretty friendly name to be displayed
    description                      = optional(string)               # Description of the Host Pool
    workspace_name                   = string                         # Workspace for the Host Pool to be associated with
    type                             = optional(string, "Pooled")     # Type of Host Pool. Possible values are "Pooled", "Personal". Defaults to "Pooled"
    load_balancer_type               = optional(string, "DepthFirst") # Load Balancer Type. Possible values are "BreadthFirst", "DepthFirst", "Persistent". "Defaults to "DepthFirst".
    validate_environment             = optional(bool, true)           # If environment should be validated or not. Defaults to "true"
    start_vm_on_connect              = optional(bool, false)          # Start VM when it's connected to. Defaults to "false"
    custom_rdp_properties            = optional(string)               # A string of Custom RDP Properties to be applied to the Host Pool
    personal_desktop_assignment_type = optional(string, "Automatic")  # Personal Desktop Assignment Type. Possible values are "Automatic" and "Direct". Defaults to "Automatic"
    maximum_sessions_allowed         = optional(number)               # Maximum number of users that have concurrent sessions on a session host. 0 - 999999. Should only be set if "type = Pooled"
    preferred_app_group_type         = optional(string)               # Preferred Application Group type for the Host Pool. Valid options are "None", "Desktop", "RailApplications". Defaults to "None"
    tags                             = optional(map(string))          # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    scheduled_agent_updates = optional(object({                       # Block defining Scheduled Agent Updates
      enabled                   = optional(bool, false)               # If Scheduled Agents Updates should be enabled or not. Defaults to "false"
      timezone                  = optional(string)                    # Specify timezone for the schedule
      use_session_host_timezone = optional(bool, true)                # Use the system timezone of the session host. Defaults to "true"
      schedule = optional(list(object({                               # List of blocks defining schedules
        day_of_week = string                                          # Specify day of week. Possible values are "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturdai", "Sunday"
        hour_of_day = number                                          # The hour of day the update window should start. The update is a 2 hour period following the hour provided.
      })))                                                            # The value should be provided as a number between 0 and 23, with 0 being midnight and 23 being 11pm.
    }))                                                               #
    registration_expiration_date = optional(string)                   # The date the registration token should expire. Recommended to use the time_offset resource for this
  }))
}


################################################
##  Input Variables - AVD Application Groups  ##
################################################
variable "avd-application_groups" {
  description = "A list of objects with one object per application group. See documentation below for values and examples."
  type = list(object({
    name                         = string                # Name of Application Group
    friendly_name                = optional(string)      # Pretty friendly name to be displayed
    description                  = optional(string)      # Description of the Application Group
    type                         = string                # Type of Application Group. Possible values are "RemoteApp" or "Desktop"
    host_pool_name               = string                # Name of Host Pool to be associated with the Application Group
    workspace_name               = string                # Name of the Workspace to be associated with the Application Group
    default_desktop_display_name = optional(string)      # Optionally set the Display Name for the default sessionDesktop desktop when "type = Desktop"
    tags                         = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
    group-avd-users-object-id    = optional(string)      # Group ID of the Azure AD group that contains the users that should have access to the session hosts
  }))
  default = []
}


##########################################
##  Input Variables - AVD Applications  ##
##########################################
variable "avd-applications" {
  description = "A list of objects with one object per application. See documentation below for values and examples."
  type = list(object({
    name                         = string           # Name of Application
    friendly_name                = optional(string) # Pretty friendly name to be displayed
    description                  = optional(string) # Description of the application
    application_group_name       = string           # Name of Application Group for the Application to be associated with
    path                         = string           # The file path location of the app on the Virtual Desktop OS
    command_line_argument_policy = string           # Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values are #DoNotAllow", "Allow", "Require"
    command_line_arguments       = optional(string) # Command Line Arguments for Application
    show_in_portal               = optional(bool)   # Specifies whether to show the RemoteApp program in the RD Web Access Server. Possible values are "true" or "false"
    icon_path                    = optional(string) # Specifies the path for an icon which will be used for this Application
    icon_index                   = optional(string) # The index of the icon you wish to use
  }))
  default = []
}


####################################################
##  Input Variables - AVD - Shared Image Gallery  ##
####################################################
variable "avd-shared-image-gallery" {
  description = "An object describing a Shared Image Gallery resource, if it should be deployed."
  type = list(object({
    name        = string                # Name of the Shared Image Gallery
    description = optional(string)      # Description of the Shared Image Gallery
    tags        = optional(map(string)) # Specify tags for the Host Pool. If not set, the main tags input is used. If no tags are set, default tags will be applied
  }))
  default = []
}


#####################
##  AVD - FSLogix  ##
#####################
variable "avd-fslogix" {
  description = "An object describing the storage account and file share for FSLogix"
  type = list(object({
    name                               = string                          # Name of Storage Account used for FSLogix
    account_tier                       = optional(string, "Premium")     # Account Tier of the Storage Account. Possible values are "Standard" or "Premium". Defaults to "Premium"
    account_kind                       = optional(string, "FileStorage") # Storage Account kind. Possible values are "BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2". Defaults to "StorageV2"
    account_replication_type           = optional(string, "LRS")         # Storage Account Replication Type. Possible values are "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS". Defaults to "LRS"
    access_tier                        = optional(string, "Hot")         # Storage Account Access Tier. Possible values are "Hot" or "Cool". Defaults to "Hot"
    azure_share_quota                  = optional(string, "100")         # The maximum size of the share, in gigabytes
    azure_domain_join_type             = optional(string)                # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed
    terraform_deployment_spn_object_id = optional(string)                # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account
    ad_group_avd_users_object_id       = optional(string)                # Object ID of the Azure AD Group containing the AVD Users
  }))
  default = []
}


###########################################
##  Input Variables - AVD Session Hosts  ##
###########################################
variable "avd-session-hosts" {
  description = "A list of objects with one object per session host. See documentation below for values and examples."
  type = list(object({
    name                      = string                                      # Name of session hosts
    session_host_count        = number                                      # Number of session hosts
    group-avd-users-object-id = optional(string)                            # Group ID of the Azure AD group that contains the users that should have access to the session hosts
    admin_username            = string                                      # Local administrator username
    admin_password            = string                                      # Local administrator password
    size                      = string                                      # VM Size SKU for the session hosts
    timezone                  = optional(string)                            # Specify timezone for the session hosts
    source_image_id           = optional(string)                            # One of either source_image_id or source_image_reference must be set
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
  }))
  default = []
}


#######################
##  Local Variables  ##
#######################
locals {
  prefix = "${var.shortname != null ? "${var.shortname}-" : ""}${var.env}"

  # Use this map with the var.env input variable as input, to translate the env to human readable
  env = {
    p     = "Production"
    d     = "Development"
    t     = "Test"
    q     = "QA"
    s     = "Staging"
    prod  = "Production"
    dev   = "Development"
    test  = "Test"
    qa    = "QA"
    stage = "Staging"
  }

  tags = var.tags == null ? local.default-tags : var.tags
  default-tags = {
    Customer    = var.shortname
    Environment = local.env[var.env]
    Location    = var.location
  }
}
