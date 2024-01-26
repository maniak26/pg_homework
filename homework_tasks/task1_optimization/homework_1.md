# Домашняя работа №1

## Задача

1. [Развернуть ПГ любым удобным способом на Линукс](#install)
2. [Провести первичный бенчмарк (простой и расширенный варианты)](#reference_benchmark)
3. [Настроить на оптимальную производительность](#optimal_config)
4. [Настроить на максимальную производительность, не обращая внимание на ACID](#extreme_fast_conig)
5. [Сдача в формате markdown на github](https://github.com/maniak26/pg_homework)

## Решение

### 1. Развернуть ПГ любым удобным способом на Линукс <a name="install"></a>

Поскольку данное действие надо будет повторять часто, целесообразно применить элементы автоматизации. В данном случае это bash скрипт и ansible-плейбуки.

#### 1.1 Создание и удаление ВМ

Чтоб 100500 раз руками создание ВМ не дергать, напишем простенький [скрипт для создания ВМ](https://github.com/maniak26/pg_homework/raw/main/ansible/createvm.sh)  в yandex cloud с нужными параметрами. В пару к нему [скрипт удаления ВМ](https://github.com/maniak26/pg_homework/raw/main/ansible/deletevm.sh) ВМ для экономии времени и денег.

```BASH
cd ansible
chmod +x ./createvm.sh && createvm.sh
```

#### 1.2 Базовая настройка ВМ

Включает в себя обновление всех существующих пакетов с ребоутом ВМ и установки ряда базовых пакетов. Выполняется [плейбуком ansible](https://github.com/maniak26/pg_homework/blob/main/ansible/0_base_config.yml)
Дополнительно добавляется swap файл размером в 1\2 от доступной RAM. Для этого используется готовая [ansible-роль](https://github.com/geerlingguy/ansible-role-swap/tree/master). В роли есть функционал установки swappiness, но его не будем использовать, оставим для начала базовое значение в 60.

```BASH
ansible-playbook -i hosts.ini 0_base_config.yml 
```

#### 1.3 Установка postgres

Добавляем официальные репозитории, ставим необходимые пакеты с помощью [плейбука](https://github.com/maniak26/pg_homework/blob/main/ansible/2_install_pgsql.yml)

```BASH
ansible-playbook -i hosts.ini 2_install_pgsql.yml
```

#### 1.4 Заливка тестовой thai db

Скачиваем на локальный ПК архив, заливаем на удаленный сервер, там разархивируем и грузим в базу с помощью [плейбука](https://github.com/maniak26/pg_homework/blob/main/ansible/4_prepare_thai_db.yml)

```BASH
ansible-playbook -i hosts.ini 4_prepare_thai_db.yml
```

### 2. Провести первичный бенчмарк (простой и расширенный варианты) <a name="reference_benchmark"></a>

Для удобства повторный запусков обернем команды ниже в [ansible плейбук](https://github.com/maniak26/pg_homework/blob/main/ansible/5_run_pgbench.yml)

```BASH
pgbench -i
pgbench -P 1 --client=20 --jobs=8 --time=60 --builtin=tpcb-like --protocol=simple --vacuum-all postgres
pgbench -P 1 --client=20 --jobs=8 --time=60 --builtin=tpcb-like --protocol=extended --vacuum-all postgres
```

Для начала убедимся что получаем валидные результаты путем трехкратного прогона одного и того же теста:

|                                           | simple test 1              | simple test 2              | simple test 3              | среднее simple             |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | simple                     | simple                     |
| number of transactions actually processed | 85195                      | 85201                      | 85612                      | 85336                      |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |
| latency average ms                        | 14,085                     | 14,085                     | 14,017                     | 14,06233333                |
| initial connection time ms                | 13,09                      | 13,382                     | 13,885                     | 13,45233333                |
| tps (without initial connection time) ms  | 1419,90739                 | 1419,951538                | 1426,873706                | 1422,244211                |

|                                           | extended test 1            | extended test 2            | extended test 2            | среднее extended           |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | extended                   | extended                   | extended                   | extended                   |
| number of transactions actually processed | 84683                      | 83250                      | 84769                      | 84234                      |
| number of failed transactions             | 0                          |                            |                            | 0                          |
| latency average ms                        | 14,171                     | 14,415                     | 14,56                      | 14,382                     |
| initial connection time ms                | 13,192                     | 12,878                     | 14,186                     | 13,41866667                |
| tps (without initial connection time) ms  | 1411,328009                | 1387,438167                | 1412,782948                | 1403,849708                |

Для сравнительной оценки будем использовать средние значения повторов тестов:

|                                           | среднее simple             | среднее extended           |
|-------------------------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          |
| number of clients                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       |
| query mode                                | simple                     | extended                   |
| number of transactions actually processed | 85336                      | 84234                      |
| number of failed transactions             | 0                          | 0                          |
| latency average ms                        | 14.0623                    | 14.382                     |
| initial connection time ms                | 13.4523                    | 13.4186                    |
| tps (without initial connection time) ms  | 1422.24421133              | 1403.8497                  |

### 3. Настроить на оптимальную производительность <a name="optimal_config"></a>

#### 3.1 Настройка Linux

Настройки будем менять [плейбуком](https://github.com/maniak26/pg_homework/blob/main/ansible/1_sysctl.yml) для упрощения повторов тестов

3.1.1 vm.swappiness = 5
3.1.2 vm.nr_hugepages = 108

TODO: вернуться к этому пункту после настройки потребления памяти postgres, т.к. сейчас значение рассчитано:

```bash
    grep ^VmPeak /proc/$(head -1 /var/lib/postgresql/15/main/postmaster.pid)/status
    # VmPeak:	  219244 kB
    grep ^Hugepagesize /proc/meminfo
    # Hugepagesize:       2048 kB
    # round (219244 / 2048) = 108
```

3.1.3 vm.overcommit_memory = 2
3.1.4 vm.overcommit_ratio = 50
3.1.5 выключены transparent_hugepage
3.1.6 Numa
В текущей конфигурации ВМ представлена только одна нода NUMA, соответственно настройки не требуются:

```bash
cat /proc/sys/vm/zone_reclaim_mode
# 0
root@pg15:~# numactl --hardware
# available: 1 nodes (0)
# node 0 cpus: 0 1 2 3 4 5 6 7
# node 0 size: 15988 MB
# node 0 free: 14685 MB
# node distances:
# node   0 
#   0:  10 
```

##### Результаты тестов

Незначительный рост показателей в пределах погрешности класса "на глазок"

| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | extended                   | extended                   |
| number of transactions actually processed | 85336                      | 88818                      | 84234                      | 85553                      |
| number of failed transactions             | 0                          |                            | 0                          |                            |
| latency average ms                        | 14.0623                    | 13.511                     | 14.382                     | 14.027                     |
| initial connection time ms                | 13.4523                    | 14.496                     | 13.4186                    | 12.687                     |
| tps (without initial connection time) ms  | 1422.24421133              | 1480.308191                | 1403.8497                  | 1425.794696                |

#### 3.2 Настройка Postgresql

##### Исходные данные

| Параметр          | Значение |
|-------------------|----------|
| Версия PG         | 15       |
| RAM, Gb           | 16       |
| CPU               | 8        |
| Disk type         | SSD      |
| Database size, Gb | 10       |
| Тим нагрузки      | OLTP     |
| Connections       | 40*      |

_* В тестах используется 20 коннектов, но по условиям задачи нужен оптимальный конфиг. Полезно иметь возможность принять больше клиентов чем закладывали без перезагрузки БД_

3.2.1 [Базовый конфиг](https://github.com/maniak26/pg_homework/blob/main/ansible/files/configs/pg_15.conf) бездумно сгенерим [конфигуратором от cybertec](https://pgconfigurator.cybertec.at/) и зальем на кластер с помощью [плейбука](https://github.com/maniak26/pg_homework/blob/main/ansible/3_config_pgsql.yml)

Получаем результаты сравнимые в пределах погрешности с эталоном и идем смотреть подробно параметры

|                                           | среднее simple             | simple + pg_conf 3.2.1       | среднее extended           | extended + pg_conf 3.2.1     |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | extended                   | extended                   |
| number of transactions actually processed | 85336                      | 88104                      | 84234                      | 84509                      |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |
| latency average ms                        | 14.0623                    | 13.621                     | 14.382                     | 14.200                     |
| initial connection time ms                | 13.4523                    | 13.549                     | 13.4186                    | 13.417                     |
| tps (without initial connection time) ms  | 1422.24421133              | 1468.278133                | 1403.8497                  | 1408.428874                |

3.2.2 Ручной тюнинг PG

Возвращаем использование huge_pages
huge_pages = off > try

Возвращаемся к пункту 3.1.2 и пересчитываем размер vm.nr_hugepages

Результат:

|                                           | среднее simple             | simple + pg_conf 3.2.2     | среднее extended           | extended + pg_conf 3.2.2   |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | extended                   | extended                   |
| number of transactions actually processed | 85336                      | 89408                      | 84234                      | 86653                      |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |
| latency average ms                        | 14.0623                    | 13.421                     | 14.382                     | 13.853                     |
| initial connection time ms                | 13.4523                    | 13.524                     | 13.4186                    | 13.049                     |
| tps (without initial connection time) ms  | 1422.24421133              | 1490.152233                | 1403.8497                  | 1443.709467                |

### 4. Настроить на оптимальную производительность, не обращая внимание на ACI_D <a name="extreme_fast_conig"></a>

4.1

synchronous_commit=off
fsync=off
full_page_writes=off

|                                           | среднее simple             | simple + pg_aci 4.1        | среднее extended           | extended + pg_aci 4.1      |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | extended                   | extended                   |
| number of transactions actually processed | 85336                      | 282533                     | 84234                      | 251300                     |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |
| latency average ms                        | 14.0623                    | 4.247                      | 14.382                     | 4.775                      |
| initial connection time ms                | 13.4523                    | 14.642                     | 13.4186                    | 13.658                     |
| tps (without initial connection time) ms  | 1422.24421133              | 4709.264234                | 1403.8497                  | 4188.570197                |

4.2 "In-memory DB нынче в моде"

Создадим ВМ с 24Gb ram, 8 из которых будем использовать как ram disk, который примонтируем в /var/lib/postgresql. Главное держать в голове что ее ребутить нельзя =)

```bash
mkdir -p /var/lib/postgresql
mount -t tmpfs -o size=8G tmpfs /var/lib/postgresql
```

|                                           | среднее simple             | simple + ram pg            | среднее extended           | extended + ram pg          |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | extended                   | extended                   |
| number of transactions actually processed | 85336                      | 274306                     | 84234                      | 245546                     |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |
| latency average ms                        | 14.0623                    | 4.374                      | 14.382                     | 4.887                      |
| initial connection time ms                | 13.4523                    | 14.090                     | 13.4186                    | 13.114                     |
| tps (without initial connection time) ms  | 1422.24421133              | 4572.159949                | 1403.8497                  | 4092.742745                |

Результат примерно сравним с отключением [synchronous_commit](https://postgrespro.ru/docs/postgresql/15/runtime-config-wal#GUC-SYNCHRONOUS-COMMIT), [fsync](https://postgrespro.ru/docs/postgresql/15/runtime-config-wal#GUC-FSYNC) и [full_page_writes](https://postgrespro.ru/docs/postgresql/15/runtime-config-wal#GUC-FULL-PAGE-WRITES)

Полезная ссылка [Как на самом деле Linux выполняет запись на диск](https://habr.com/ru/companies/nmg/articles/750794/)
