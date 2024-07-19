resource "yandex_kubernetes_cluster" "otus-kluster" {
 name = "otus-kluster"
 network_id = yandex_vpc_network.kubered-net.id
 folder_id = var.folder_id
 master {
   master_location {
      zone      = yandex_vpc_subnet.kubered-net-ru-central1-a.zone
      subnet_id = yandex_vpc_subnet.kubered-net-ru-central1-a.id
   }
   public_ip = true
 }
 service_account_id      = yandex_iam_service_account.k8s-res-sa.id
 node_service_account_id = yandex_iam_service_account.k8s-res-sa.id
   depends_on = [
      yandex_resourcemanager_folder_iam_member.editor,
      yandex_resourcemanager_folder_iam_member.images-puller
   ]
}

resource "yandex_vpc_network" "kubered-net" { 
  name = "kubered-net"
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "kubered-net-ru-central1-a" {
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-a"
  folder_id = var.folder_id
  network_id     = yandex_vpc_network.kubered-net.id
}

// Создание сервисного аккаунта k8s-res-sa и роли для него
resource "yandex_iam_service_account" "k8s-res-sa" {
  name        = "k8s-res-sa"
  folder_id = var.folder_id
  description = "Сервесный аккаунт для куберенетиса для ресурсов"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-res-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_clusters_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-res-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "res_vpc_publicAdmin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-res-sa.id}"
}

// Создание сервисного аккаунта k8s-node-sa и роли для него
resource "yandex_iam_service_account" "k8s-node-sa" {
  name        = "k8s-node-sa"
  folder_id = var.folder_id
  description = "Сервесный аккаунт для куберенетиса для узлов"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-node-sa.id}"
}

// Создание сервисного аккаунта k8s-ic-sa и роли для него
resource "yandex_iam_service_account" "k8s-ic-sa" {
  name        = "k8s-ic-sa"
  folder_id = var.folder_id
  description = "Сервесный аккаунт для куберенетиса для работы Application Load Balancer Ingress-контроллера"
}

resource "yandex_resourcemanager_folder_iam_member" "alb_editor" {
  folder_id = var.folder_id
  role      = "alb.editor"
 member    = "serviceAccount:${yandex_iam_service_account.k8s-ic-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ic_vpc_publicAdmin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-ic-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "certificate-manager_certificates_downloader" {
  folder_id = var.folder_id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-ic-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "compute_viewer" {
  folder_id = var.folder_id
  role      = "compute.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-ic-sa.id}"
}
