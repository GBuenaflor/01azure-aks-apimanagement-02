#######################################################
# Azure Terraform - Infrastructure as a Code (IaC)
#  
# - Azure Kubernetes 
#    - Advance Networking - Azure CNI
#
# azurerm_virtual_network
#  azurerm_subnet
#  azurerm_network_security_group
# azurerm_container_registry
# azurerm_api_management
# azurerm_application_gateway
# azurerm_kubernetes_cluster
# 
# Add Route Table and associate all subnets to it
# Add KeyValut with 2 Certificate
#
# ----------------------------------------------------
#  Initial Configuration
# ----------------------------------------------------
# - Run this in Azure CLI
#   az login
#   az ad sp create-for-rbac -n "AzureTerraform" --role="Contributor" --scopes="/subscriptions/[SubscriptionID]"
#
# - Then complete the variables in the variables.tf file
#   - subscription_id  
#   - client_id  
#   - client_secret  
#   - tenant_id  
#   - ssh_public_key  
#   - access_key
# 
#
####################################################### 
#----------------------------------------------------
# Azure Terraform Provider
#----------------------------------------------------

provider "azurerm" { 
  features {}
  version = ">=2.0.0"  
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id 
}

#----------------------------------------------------
# Resource Group
#----------------------------------------------------

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group
  location = var.location
}
  
#----------------------------------------------------
# azurerm_virtual_network
#----------------------------------------------------

resource "azurerm_virtual_network" "az-vnet01" {
  name                = "az-vnet01"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = [var.virtual_network_address_prefix]
 
  tags = {
    Environment = var.environment
  }
}
 

resource "azurerm_subnet" "az-appgw-sub" {
  name                 = "az-appgw-sub"
  virtual_network_name = azurerm_virtual_network.az-vnet01.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = [var.app_gateway_subnet_address_prefix]
}

resource "azurerm_subnet" "az-apim-sub" {
  name                 = "az-apim-sub"
  virtual_network_name = azurerm_virtual_network.az-vnet01.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = [var.api_management_subnet_address_prefix]
}

 

resource "azurerm_subnet" "az-k8s-sub" {
  name                 = "az-k8s-sub" 
  virtual_network_name = azurerm_virtual_network.az-vnet01.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = [var.az_k8s_subaddress_prefix]
}


resource "azurerm_subnet" "az-k8s-vm-sub" {
  name                 = "az-k8s-vm-sub" 
  virtual_network_name = azurerm_virtual_network.az-vnet01.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = [var.az_k8s_linux_sub_address_prefix]
}
 
#----------------------------------------------------
# azurerm_network_security_group , azurerm_subnet_network_security_group_association
#----------------------------------------------------
resource "azurerm_network_security_group" "az-nsg01" {
  name                = "az-nsg01"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "az-nsg-rule01"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"  # "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "az-nsg02" {
  name                = "az-nsg02"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "az-nsg-rule02"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"  # "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "az-nsg03" {
  name                = "az-nsg03"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "az-nsg-rule03"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"  # "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
 

resource "azurerm_subnet_network_security_group_association" "az-nsg-association01" {
  subnet_id                 = azurerm_subnet.az-appgw-sub.id
  network_security_group_id = azurerm_network_security_group.az-nsg01.id
}


resource "azurerm_subnet_network_security_group_association" "az-nsg-association02" {
  subnet_id                 = azurerm_subnet.az-apim-sub.id
  network_security_group_id = azurerm_network_security_group.az-nsg02.id
}
 
resource "azurerm_subnet_network_security_group_association" "az-nsg-association03" {
  subnet_id                 = azurerm_subnet.az-k8s-sub.id
  network_security_group_id = azurerm_network_security_group.az-nsg03.id
}

resource "azurerm_subnet_network_security_group_association" "az-nsg-association04" {
  subnet_id                 = azurerm_subnet.az-k8s-vm-sub.id
  network_security_group_id = azurerm_network_security_group.az-nsg03.id
}
 
#----------------------------------------------------
# Public Ip (Port 80)
#---------------------------------------------------- 

resource "azurerm_public_ip" "az-pip-80" {
  name                = "az-pip-80"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}
 
#----------------------------------------------------
# Public Ip (Port 443)
#---------------------------------------------------- 

resource "azurerm_public_ip" "az-pip-443" {
  name                = "az-pip-443"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}


#----------------------------------------------------
# azurerm_container_registry 
# You can also add ACR for Prod. FOr testing I use Dockerhub
#----------------------------------------------------
   
#resource "azurerm_container_registry" "azacrapi01" {
#  name                     = "azacr10"
#  location                 = azurerm_resource_group.resource_group.location
#  resource_group_name      = azurerm_resource_group.resource_group.name
#  sku                      = "Standard" # "Premium"
#  admin_enabled            = false
#  #georeplication_locations = ["East US", "West Europe"] # available in Premium only
#}  


#----------------------------------------------------
# azurerm_api_management
#---------------------------------------------------- 
 
  resource "azurerm_api_management" "az-apim01" {
  name                 = "az-apim01"
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  publisher_name       = "gb"
  publisher_email      = "YourEmailAddressHere"
  
  sku_name             = "Developer_1" # Consumption, Developer, Basic, Standard and Premium
    
  virtual_network_type = "Internal"
  virtual_network_configuration  {   
    subnet_id          = azurerm_subnet.az-apim-sub.id
  }
  
	
  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
  XML

  }
  
  depends_on = [
    azurerm_virtual_network.az-vnet01,
    azurerm_subnet.az-apim-sub
  ]
}

#----------------------------------------------------
# Application Gateway
#---------------------------------------------------- 
 
resource "azurerm_application_gateway" "az-appgateway01" {
  name                = "az-appgateway01"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  sku {
    name     = var.app_gateway_sku
    tier     = var.app_gateway_tier
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "az-appgateway-ip-config01"
    subnet_id = azurerm_subnet.az-appgw-sub.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }
 
  frontend_ip_configuration {
    name                 = "frontend_ip_configuration01"   # Port 80
    public_ip_address_id = azurerm_public_ip.az-pip-80.id
  }
 
  
  backend_address_pool {
    name = "backend_address_pool01"
  }

  backend_http_settings {
    name                  = "backend_http_settings01"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "http_listener01"
    frontend_ip_configuration_name = "frontend_ip_configuration01"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }
 
  
  request_routing_rule {
    name                       = "request_routing_rule01"  # 80
    rule_type                  = "Basic"
    http_listener_name         = "http_listener01"
    backend_address_pool_name  = "backend_address_pool01"
    backend_http_settings_name = "backend_http_settings01"
  }
 
  waf_configuration {
    enabled                  = "true"
    firewall_mode            = "Prevention"  # Detection 
    rule_set_type            = "OWASP"
    rule_set_version         = "3.1"   # 2.2.9, 3.0, and 3.1 
    file_upload_limit_mb     = 200     # 1MB to 500MB, Defaults to 100MB 
    max_request_body_size_kb = 128     # 1KB to 128KB. Defaults to 128KB 
	# request_body_check     = "true"  # false	
  }
  
  tags = {
    Environment = var.environment
  }
  
  depends_on = [
    azurerm_virtual_network.az-vnet01,
    azurerm_public_ip.az-pip-80
  ]
}
 
 
#----------------------------------------------------
# azurerm_log_analytics_workspace , azurerm_log_analytics_solution
# YOu can also add this component
#----------------------------------------------------
   
#resource "azurerm_log_analytics_workspace" "azloganalytics01" {
#  name                = "azloganalytics01"
#  location            = azurerm_resource_group.resource_group.location
#  resource_group_name = azurerm_resource_group.resource_group.name
#  sku                 = "Standard"
#}


#resource "azurerm_log_analytics_solution" "azakslogsolution01" {
#    solution_name         = "ContainerInsights"
#    location              = azurerm_resource_group.resource_group.location
#    resource_group_name   = azurerm_resource_group.resource_group.name
#
#    workspace_resource_id = azurerm_log_analytics_workspace.azloganalytics01.id
#    workspace_name        = azurerm_log_analytics_workspace.azloganalytics01.name
#
#    plan {
#        publisher = "Microsoft"
#        product   = "OMSGallery/ContainerInsights"
#    }
#	
#	depends_on = [
#    azurerm_log_analytics_workspace.azloganalytics01 
#  ]
#}

#----------------------------------------------------
# Azure AKS Cluster (with Advance Networking,network_plugin: Azure)
# azurerm_kubernetes_cluster_node_pool
#----------------------------------------------------

resource "azurerm_kubernetes_cluster" "az-k8s" {
  name                = "az-k8s"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = var.dns_prefix

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }
  
  addon_profile {
    http_application_routing {
      enabled = false
    }
#	oms_agent {
#        enabled                    = true
#        log_analytics_workspace_id = azurerm_log_analytics_workspace.azloganalytics01.id
#        }
  }
  
  default_node_pool {
    name                 = "nodel" 
    vm_size              = var.vm_size 
    os_disk_size_gb      = var.aks_agent_os_disk_size
    vnet_subnet_id       = azurerm_subnet.az-k8s-sub.id  
		
    enable_auto_scaling  = var.autoscale
    node_count           = var.node_count
    max_count            = var.autoscale_max_count 
    min_count            = var.autoscale_min_count
	
	#cluster_auto_scaling           = false
    #cluster_auto_scaling_min_count = null
    #cluster_auto_scaling_max_count = null
  }
 
  
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }
 
  depends_on = [
    azurerm_virtual_network.az-vnet01,
    #azurerm_application_gateway.az-appgateway01,
  ]
  
  tags = {
    Environment = var.environment
  }
}
  
  
#----------------------------------------------------
# azurerm_kubernetes_cluster_node_pool
#----------------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "nodew" {
  name                   = "nodew"
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.az-k8s.id
    vm_size              = var.vm_size
	os_type              = "Windows"
    os_disk_size_gb      = var.aks_agent_os_disk_size
    vnet_subnet_id       = azurerm_subnet.az-k8s-sub.id   
		
    enable_auto_scaling  = var.autoscale
    node_count           = var.node_count
    max_count            = var.autoscale_max_count 
    min_count            = var.autoscale_min_count
	
	#cluster_auto_scaling           = false
    #cluster_auto_scaling_min_count = null
    #cluster_auto_scaling_max_count = null

  tags = {
    Environment = var.environment
  }
	depends_on = [
    azurerm_kubernetes_cluster.az-k8s 
  ]
}
   