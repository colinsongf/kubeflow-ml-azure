# create a resource group 
resource "azurerm_resource_group" "dcoe_rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

# Create AKS Cluster

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.dcoe_rg.location}"
  resource_group_name = "${azurerm_resource_group.dcoe_rg.name}"
  dns_prefix          = "${var.dns_prefix}"
  kubernetes_version  = "${var.kubernetes_version}"

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.agent_count}"
    vm_size         = "${var.vm_size}"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${var.azure_client_id}"
    client_secret = "${var.azure_client_secret}"
  }

  tags {
    Environment = "Development"
  }
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config_raw}"
}

output "host" {
  value = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
}

resource "azurerm_container_registry" "acr" {
  name                = "${replace(azurerm_resource_group.dcoe_rg.name, "-", "")}acr"
  resource_group_name = "${azurerm_resource_group.dcoe_rg.name}"
  location            = "${azurerm_resource_group.dcoe_rg.location}"
  sku                 = "standard"
}

# Storage account for AKS cluster
resource "azurerm_storage_account" "storageac" {
  name                     = "${replace(azurerm_resource_group.dcoe_rg.name, "-", "")}dcoesac"
  resource_group_name      = "${azurerm_kubernetes_cluster.k8s.node_resource_group}"
  location                 = "${azurerm_resource_group.dcoe_rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "Development"
  }
}


#TODO This is not working properly yet,
# Needs a way to authenticate Azure Kubernetes Cluster with container registry
# See https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aks

# resource "random_string" "password" {
#   length = 32
# }

# resource "azurerm_azuread_service_principal" "service_principal" {
#   application_id = "${azurerm_kubernetes_cluster.k8s.id}"
#}

# resource "azurerm_azuread_service_principal_password" "service_principal" {
#   service_principal_id = "${azurerm_azuread_service_principal.service_principal.id}"
#   value                = "${random_string.password.result}"
#   end_date             = "2020-01-01T01:02:03Z"
# }

//resource "azurerm_role_assignment" "acr-assignment" {
//  scope                = "${azurerm_container_registry.acr.id}"
//  role_definition_name = "Reader"
//  principal_id         = "${azurerm_azuread_service_principal.service_principal.application_id}"
//  depends_on           = ["azurerm_azuread_service_principal.service_principal"]
//}had

# output "object_id" {
#   description = "The Object ID for the Service Principal."
#   value       = "${azurerm_azuread_service_principal.service_principal.id}"
# }

# output "password" {
#   description = "The Password for this Service Principal."
#   value       = "${azurerm_azuread_service_principal_password.service_principal.value}"
# }


# Jenkins
resource "azurerm_resource_group" "jenkins_rg_name" {
  name     = "${var.jenkins_rg_name}"
  location = "${var.location}"
  tags {
    environment = "jenkins"
  }
}

# Storage account for AKS cluster
resource "azurerm_storage_account" "jenkinsstorageac" {
  name                     = "${replace(azurerm_resource_group.jenkins_rg_name.name, "_","")}jstoracc"
  resource_group_name      = "${azurerm_resource_group.jenkins_rg_name.name}"
  location                 = "${azurerm_resource_group.jenkins_rg_name.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags {
    environment = "jenkins"
  }
}

resource "azurerm_virtual_network" "jenkinsvn" {
  name                = "${format("%s-%s", var.jenkins_rg_name, "vnet")}"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.jenkins_rg_name.name}"

  tags {
    environment = "jenkins"
  }
}

resource "template_dir" "azure_file_sc" {
  source_dir      = "${path.module}/templates"
  destination_dir = "${path.cwd}/rendered"

  vars {
    storage_account = "${azurerm_storage_account.storageac.name}"
  }
}
