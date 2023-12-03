terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.70.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.41.0"
    }
  }
}

provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  client_id = var.client_id
  client_secret = var.client_secret
  features {}
}

resource "azurerm_resource_group" "astroTurfTest1" {
  name = "astroTurf"
  location = "Central US"
}

resource "azurerm_user_assigned_identity" "astroBoy" {
  location = "Central US"
  name = "astroBoy"
  resource_group_name = azurerm_resource_group.astroTurfTest1.name
  
}

resource "azurerm_key_vault" "astroVault" {
  name = "astroVault"
  location = azurerm_resource_group.astroTurfTest1.location
  resource_group_name = azurerm_resource_group.astroTurfTest1.name
  enabled_for_disk_encryption = true
  tenant_id = var.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled = true
  sku_name = "standard"
  
  }

resource "azurerm_key_vault_access_policy" "astroaccesspolicy" {
  key_vault_id = azurerm_key_vault.astroVault.id
  tenant_id = var.tenant_id
  object_id = azurerm_user_assigned_identity.astroBoy.principal_id

  key_permissions = [
    "Get", 
    "Create",
    "Backup",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy",
    ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover", 
    "Restore",
    "Set",
    ]

  storage_permissions = [
    "Backup",
    "Delete",
    "DeleteSAS",
    "Get",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update",
    ]
  depends_on = [ azurerm_key_vault.astroVault ]
  
}

data "azuread_service_principal" "terrPrinciple" {
  display_name = "Terraform"
}

resource "azurerm_key_vault_access_policy" "TerraAccessPolicy" {
  key_vault_id = azurerm_key_vault.astroVault.id
  tenant_id = var.tenant_id
  object_id = data.azuread_service_principal.terrPrinciple.object_id

  key_permissions = [
    "Get", 
    "Create",
    "Backup",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy",
    ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover", 
    "Restore",
    "Set",
    ]

  storage_permissions = [
    "Backup",
    "Delete",
    "DeleteSAS",
    "Get",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update",
    ]
  depends_on = [ azurerm_key_vault.astroVault ]
  
}


resource "azurerm_role_assignment" "cryptoService" {
  scope = azurerm_key_vault.astroVault.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id = azurerm_user_assigned_identity.astroBoy.principal_id

  depends_on = [ 
    azurerm_key_vault_access_policy.astroaccesspolicy, 
    azurerm_key_vault_access_policy.TerraAccessPolicy
    ]
  
}

resource "azurerm_key_vault_key" "tfstate" {
  name = "tfState"
  key_vault_id = azurerm_key_vault.astroVault.id
  key_type = "RSA"
  key_size = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P07D"
    }

    expire_after = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [ 
    azurerm_role_assignment.cryptoService
    ]
  
}



resource "azurerm_storage_account" "TerraState" {
  name = "tfstatestore1234545"
  resource_group_name = azurerm_resource_group.astroTurfTest1.name
  location = azurerm_resource_group.astroTurfTest1.location
  account_tier = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.astroBoy.id]
  }

  lifecycle {
    ignore_changes = [ customer_managed_key ]
  }

  depends_on = [ 
    azurerm_key_vault.astroVault, 
    azurerm_key_vault_key.tfstate ]
  
}

resource "azurerm_key_vault_access_policy" "storage" {
  key_vault_id = azurerm_key_vault.astroVault.id
  tenant_id = var.tenant_id
  object_id = azurerm_storage_account.TerraState.identity.0.principal_id

  key_permissions = [
    "Get", 
    "Create",
    "Backup",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy",
    ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover", 
    "Restore",
    "Set",
    ]

  storage_permissions = [
    "Backup",
    "Delete",
    "DeleteSAS",
    "Get",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update",
    ]
  depends_on = [ azurerm_storage_account.TerraState ]
  
}
  

data "azurerm_key_vault_key" "keyfeed" {
  name = "tfstate"
  key_vault_id = azurerm_key_vault.astroVault.id
  
}

resource "azurerm_storage_account_customer_managed_key" "tfstate" {
  storage_account_id = azurerm_storage_account.TerraState.id
  key_vault_id = azurerm_key_vault.astroVault.id
  key_name = data.azurerm_key_vault_key.keyfeed.name

  depends_on = [ azurerm_storage_account.TerraState ]
  
}
