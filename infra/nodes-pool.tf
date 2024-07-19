// Создание группы узлов
resource "yandex_kubernetes_node_group" "worker" {
  cluster_id        = "${yandex_kubernetes_cluster.otus-kluster.id}"
  name              = "worker"
  description       = "Для кластера проекта ОТУС"
  node_labels = {
    work  = "true"
  }

  instance_template {
    name = "work-{instance.index}"
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.kubered-net-ru-central1-a.id}"]
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}

resource "yandex_kubernetes_node_group" "infra" {
  cluster_id            = "${yandex_kubernetes_cluster.otus-kluster.id}"
  name                  = "infra"
  description           = "Для кластера проекта ОТУС"
  node_labels = {
      infra = "true"
  }
  node_taints            = [
    "node-role=infra:NoSchedule"
  ]

  instance_template {
    name = "infra-{instance.index}"
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.kubered-net-ru-central1-a.id}"]
    }

    resources {
      memory = 4
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }
}
