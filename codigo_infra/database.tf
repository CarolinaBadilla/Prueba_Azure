resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_container_app" "postgres_db" {
  name                         = "db-postgres"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.app_rg.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  ingress {
    external_enabled = false
    target_port      = 5432
    exposed_port     = 5432
    transport        = "tcp"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    volume {
      name         = "pgdata-vol"
      storage_type = "EmptyDir"
    }

    container {
      name   = "postgres"
      image  = "postgres:16-alpine"
      cpu    = 0.5
      memory = "1Gi"

      volume_mounts {
        name = "pgdata-vol"
        path = "/var/lib/postgresql/data"
      }

      env {
        name  = "POSTGRES_USER"
        value = "pgadmin"
      }

      env {
        name  = "POSTGRES_PASSWORD"
        value = random_password.db_password.result
      }

      env {
        name  = "POSTGRES_DB"
        value = "tareasdb"
      }

      env {
        name  = "PGDATA"
        value = "/var/lib/postgresql/data/pgdata"
      }
    }
  }
}

# checkov:skip=CKV_AZURE_41:Rotacion gestionada por Terraform en entorno dev
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "database-url"
  value        = "postgresql://pgadmin:${urlencode(random_password.db_password.result)}@db-postgres:5432/tareasdb"
  content_type = "text/plain"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin]
}
