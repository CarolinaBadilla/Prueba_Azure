resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "id-aca-fullstack-dev"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

resource "azurerm_role_assignment" "aca_kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "law-fullstack-${random_string.suffix.result}"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "aca_env" {
  name                       = "cae-fullstack-dev"
  location                   = azurerm_resource_group.app_rg.location
  resource_group_name        = azurerm_resource_group.app_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = azurerm_subnet.snet_aca.id
  tags                       = local.common_tags
}

resource "azurerm_container_app" "backend_app" {
  name                         = "api-backend"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  secret {
    name                = "db-url"
    key_vault_secret_id = azurerm_key_vault_secret.db_connection_string.versionless_id
    identity            = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "backend"
      image  = "${azurerm_container_registry.acr.login_server}/fullstack-backend:v1"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "db-url"
      }

      env {
        name  = "ENVIRONMENT"
        value = "dev-azure"
      }
    }
  }

  lifecycle {
     ignore_changes = [
       template[0].container[0].image
     ]
   }

  depends_on = [
    azurerm_role_assignment.aca_acr_pull,
    azurerm_role_assignment.aca_kv_secrets_user
  ]
}

resource "azurerm_container_app" "frontend_app" {
  name                         = "web-frontend"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 2

    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/fullstack-frontend:v2"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  lifecycle {
     ignore_changes = [
       template[0].container[0].image
     ]
   }

  depends_on = [
    azurerm_role_assignment.aca_acr_pull
  ]
}
