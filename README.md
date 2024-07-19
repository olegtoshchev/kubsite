# OTUS дипломный проект
## Состав проекта
В проекте в качестве приложения примера использовано [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo). Среда развертывания managed-kubernetes от yandex cloud. Инфраструктура проекта в облаке описана и развернута с помощью terraform. Helm для развертывания приложения и инструментов. Для хранения кода и автоматизации процессов выбран gitlab.  
Ссылки:  
- [app](https://momored.fun/)
- [grafana](https://grafana.momored.fun)
- [polaris](https://polaris.momored.fun)
- [gitlab project](https://gitlab.com/sk801918/diplom-otus)

## Репозиторий
Проект размещен в офицальном репозитории gitlab.com. В проекте используется Downstream pipelines для GitLab CI/CD, в корне репозитория родительский конвейер, в директориях app, infra, tools размещены дочерние конвейеры. Родительский конвейер настроен таким образом что бы запускать дочерние при изменении в директории с дочерним конвейером. Такое решение позволяет разделить процессы создания инфраструктуры, развертывания приложения и инструментов. В родительском конвейере используется стратегия depend для того, что бы в случае падения дочернего ошибка отобразилась и в основном.  
Разработка ведется в отдельных ветках, деплой происходит при мердже в main.

## Терраформ 
В директории infra описана инфраструктура проекта:
- сервисные акаунты и роли для них
- kubernetes кластер 
- ноды
- сети

Для пула инфраструктурных нод добавлен taints NoSchedule. Состояние терраформ хранит в S3. Переменные хранятся в разделе гитлаба variables и экспортируются в локальные переменные ранера при запуске конвейера.  
На стейдже validate и plan выполняется инициализация, валидация и создается план что бы ознакомиться с изменениями.  
При слиянии в main выполняются стейджи plan и deplo. В плане еще раз можно ознакомиться с изменениями и он сохраняется в виде артефакта для передачи в следующую задачу. Запуск deploy настроен по кнопке, в ручном режиме, для большей безопасности, аналогичным образом настроен destroy на случай если надо все удалить. Таким образом при слиянии в main получаем кластер под ключ.

## Приложение
В app из репозитория [Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo), скопирован helm чарт. Для развертывания приложения дочерний конвеер использует готовый образ alpine/k8s:1.30.0. Тригером для запуска конвеера служит изменение в директории app и слияние в main. Перед выполнением скрипта из переменных гитлаба в ранере создается kubeconfig для доступа к кластеру. 
Развертывание приложения из helm чарта в app, выполняется командой:  
`helm upgrade --install boutique app/helm-chart --create-namespace -n app`

В helm чарт добавлен ingress.yaml. Приложение доступно по адресу https://momored.fun/ 

## Инструменты
Под инструментами связка из Grafana + Prometheus + Loki. Для развертывания приложения дочерний конвейер использует готовый образ alpine/k8s:1.30.0. Перед выполнением скрипта из переменных гитлаба в ранере создается kubeconfig для доступа к кластеру. Для Grafana и Loki в секции before_script добавлем репозиторий:  
`helm repo add grafana https://grafana.github.io/helm-charts`

В директории tools создаем и заполняем файлы с переменными grafana-values.yaml, loki-values.yaml и promtail-values.yaml в которых описываем нужную нам конфигурацию. Установка выполняется следующими кмандами:  
`helm upgrade --install boutique-grafana grafana/grafana -f tools/grafana-values.yaml -n tools`  
`helm upgrade --install --values tools/loki-values.yaml loki --namespace=tools grafana/loki --version 5.47.0`  
`helm upgrade --values tools/prometheus-values.yaml --install promtail grafana/promtail -n tools`  

Grafana доступна по адресу https://grafana.momored.fun. Для Loki хранит логи в S3 бакете

Установка prometheus выполняется схожим образом:  
`helm upgrade --install boutique-prometheus -f tools/prometheus-values.yaml -n tools --create-namespace oci://registry-1.docker.io/bitnamicharts/kube-prometheus`

В файлах с переменными указан пул для создания под и прописано tolerations для исключения из общего запрета на размещения под в пуле нод infra. Так же для Grafana добавлены настройки ingress и экспорт готовых дашбордов из https://grafana.com/grafana/dashboards/. Настроен datasources для Loki и Prometheus.

Для выявления проблем с безопасностью и анализа кластера развернут Polaris, доступен по адресу https://polaris.momored.fun. В директории tools файл с переменными polaris-values.yaml c описанием нужной конфигурации. Установка выполняется следующими кмандами:  
`helm repo add fairwinds-stable https://charts.fairwinds.com/stable`  
`helm upgrade --install polaris fairwinds-stable/polaris -f tools/polaris-values.yaml --namespace tools --create-namespace`
