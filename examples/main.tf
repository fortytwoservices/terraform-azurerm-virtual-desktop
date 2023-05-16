# This example contains a typical, basic deployment of an Azure Virtual Desktop environment.
# Most of the parameters and inputs are left to their default values, as they are typically the correct values in a common deployment.
# Refer to the [documentation](https://github.com/amestofortytwo/terraform-azurerm-virtual-desktop) for all available input parameters.

module "avd1" {
  source = "github.com/amestofortytwo/terraform-azurerm-virtual-desktop.git" # This referes to the latest version of the source repo. It's recommended to specify the release version!

  customer_shortname = local.shortname    # Shortname appended to the beginning of all resources. Ommit to
  env                = "d"                # Dev, module expects single letter
  location           = var.location       # Default location for resources
  tags               = local.default-tags # Default tags for resources

  avd-workspaces = [                # A list of objects describing one or more AVD Workspaces
    {                               #
      name          = "ws1"         # Name of Workspace
      friendly_name = "Workspace 1" # Pretty display name for the Workspace
    }
  ]

  avd-host_pools = [                                                                  # A list of objects describing one or more AVD Host Pools
    {                                                                                 #
      name                         = "hp1"                                            # Name of Host Pool
      friendly_name                = "HostPool1"                                      # Pretty display name for the Host Pool
      description                  = "First AVD Demo host pool"                       # Description of the Host Pool. What hosts does it contain?
      workspace_name               = "ws1"                                            # Name of the AVD Workspace for the Host Pool to be associated with
      registration_expiration_date = time_offset.registration-expiration-date.rfc3339 # Time and Date in RFC3339 format that the Host Pool registration token expires. It's recommended to use the time_offset resource for this
      custom_rdp_properties        = "targetisaadjoined:i:1;"                         # A list of custom RDP properties. The one used here is needed if you plan to connec to your AVD environment from clients that are not AAD joined to the same directory
    }
  ]

  avd-application_groups = [                                                      # A list of objects describing one or more AVD Application Groups
    {                                                                             #
      name                      = "ag1"                                           # Name of the Application Group
      friendly_name             = "Application Group1"                            # Pretty display name for the Applicatino Group
      description               = "Application Group 1 for Azure Virtual Desktop" # Description of the Application Group. What does it contain?
      type                      = "Desktop"                                       # Type of Application Group. Possible values are "RemoteApp" or "Desktop"
      host_pool_name            = "hp1"                                           # Name of Host Pool to be associated with the Application Group
      workspace_name            = "ws1"                                           # Name of the Workspace to be associated with the Application Group
      group-avd-users-object-id = azuread_group.avd-users.object_id               # Group ID of the Azure AD group that contains the users that should have access to the session hosts
    }
  ]

  avd-shared-image-gallery = [                    # A list of objects describing one or more Azure Shared Image Galleries
    {                                             #
      name        = "sig1"                        # Name of the Shared Image Gallery
      description = "Test shared image gallery 1" # Description of the Shared Image Gallery
    }
  ]

  avd-fslogix = [                                                                           # A list of objects describing one or more deployments of FSLogix
    {                                                                                       #
      name                               = "fslogix"                                        # Name of the Azure Storage Account used for FSLogix
      azure_domain_join_type             = "AADKERB"                                        # Allowed values are "AD", "AADKERB", "AADDS". Defaults to "null" and no domain join is performed
      terraform_deployment_spn_object_id = azuread_service_principal.tfdeployment.object_id # Object ID of the Terraform Deployment Service Principal, to assign correct rights to the FSLogix storage account
      ad_group_avd_users_object_id       = azuread_group.avd-users.object_id                # Object ID of the Azure AD Group containing the AVD Users
    }
  ]

  avd-session-hosts = [                                                           # A list of objects describing a set of Session Hosts
    {                                                                             #
      name                      = "sh1"                                           # Name of set of Session Hosts. Each Session Host will get this name + an incrementing number
      session_host_count        = 1                                               # How many Session Hosts to be deployed in this set
      group-avd-users-object-id = azuread_group.avd-users.object_id               # Object ID of the Azure AD Group containing the AVD Users that should have access to this set of Session Hosts
      admin_username            = "marvin"                                        # Local Administrator username
      admin_password            = random_password.avd1.result                     # Local Administrator password
      subnet_id                 = azurerm_subnet.networking-infra["infra-avd"].id # Subnet ID that this set of Session Hosts should be attached to
      size                      = "Standard_DS1_v2"                               # VM Size SKU to be used for this set of Session Hosts
      source_image_reference = {                                                  # Source Image Reference
        publisher = "MicrosoftWindowsDesktop"                                     # Image Publisher
        offer     = "office-365"                                                  # Image Offer
        sku       = "win11-22h2-avd-m365"                                         # Image SKU
        version   = "22621.963.221213"                                            # Image Version
      }                                                                           #
      os_disk = {                                                                 # Operating System Disk block
        name                 = "osdisk"                                           # Name of OS disk
        caching              = "ReadWrite"                                        # Caching Type. Possible values are "None", "ReadOnly", "ReadWrite"
        storage_account_type = "Standard_LRS"                                     # Storage Account Type. Possible values are "Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"
      }
      data_disks = [                 # A list of objects describing additional Data Disks to be created and attached to each Session Host
        {                            #
          name         = "datadisk1" # Name of Data Disk
          disk_size_gb = 32          # Size of Data Disk
          lun          = 0           # Unique LUN number for Data Disk
        }
      ]
      avd_session_host_registration_modules_url = local.avd_session_host_registration_modules_url # AVD Session Host registration DCS modules URL
      host_pool_name                            = "hp1"                                           # Name of the Host Pool for this set of Session Hosts to be registered to
    }
  ]

  depends_on = [                             # It is recommended to set dependencies for resources indirectly used by the module
    time_offset.registration-expiration-date # to make sure they are up to date before any changes are attempted on the resources
  ]                                          # created by the module
}
