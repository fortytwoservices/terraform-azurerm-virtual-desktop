# Terraform Module - Azure Virtual Desktop

---

This module deploys all resources needed for deploying Azure Virtual Desktop.

| :exclamation:  NB! |
|---|
| This module does not currently deploy Azure Files Share and Files Directory for FSLogix due to a bug in the AzureRM Terraform Provider. This step has to be completed manually in scenarios where FSLogix is needed. |

## Resources deployed by this module

Which resources, and how many of each depends on your configuration

- Resource Groups
- AVD Workspaces
- AVD Host Pools
- AVD Application Groups
- AVD Applications
- Azure Shared Image Gallery
- Azure Storage Account for FSLogix
- Windows Virtual Machines as session hosts. Either joined to Entra ID or Azure Active Directory Domain Services joined. Will be registered to the specified Host Pool

Complete list of all Terraform resources deployed is provided at the bottom of this page.

## Resources NOT deployed by this module

- Azure Virtual Network
- Azure Subnet
- Azure Network Security Groups
- Entra ID Groups - Typically for designating AVD Users and Admins
- Azure Key Vault - Typically for storage of secrets created by the module. Available in module outputs.
- Azure Active Directory Domain Services
