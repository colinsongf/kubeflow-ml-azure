variable "azure_subscription_id" { }
variable "azure_client_id" { }
variable "azure_client_secret" { }
variable "azure_tenant_id" { }
variable "ssh_public_key" {}

variable "resource_group_name" {
  default = "dcoe_rg"
}

variable "location" {
  default = "North Europe"
}

# Kubernetes variables
variable "agent_count" {
  default = "5"
}
variable "vm_size" {
  default = "Standard_DS3_v2"
}
variable "dns_prefix" {
  default = "kubeflow"
}

variable "cluster_name" {
  default = "kubeflow"
}

variable "jenkins_rg_name" {
  default = "jenkins_rg"
}
