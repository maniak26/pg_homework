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

Для удобства повторный запусков обернем команды ниже в [ansible плейбук](https://github.com/maniak26/pg_homework/blob/homework_1/ansible/5_run_pgbench.yml)

```BASH
pgbench -i
pgbench -P 1 --client=20 --jobs=8 --time=60 --builtin=tpcb-like --protocol=simple --vacuum-all postgres
pgbench -P 1 --client=20 --jobs=8 --time=60 --builtin=tpcb-like --protocol=extended --vacuum-all postgres
```

Для начала убедимся что получаем валидные результаты путем трехкратного прогона одного и того же теста:

|                                           | simple test 1              | simple test 2              | simple test 3              | extended test 1            | extended test 2            | extended test 2            |
|-------------------------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| transaction type                          | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> | <builtin: TPC-B (sort of)> |
| scaling factor                            | 1                          | 1                          | 1                          | 1                          | 1                          | 1                          |
| number of clients                         | 20                         | 20                         | 20                         | 20                         | 20                         | 20                         |
| number of threads                         | 8                          | 8                          | 8                          | 8                          | 8                          | 8                          |
| maximum number of tries                   | 1                          | 1                          | 1                          | 1                          | 1                          | 1                          |
| duration                                  | 60 s                       | 60 s                       | 60 s                       | 60 s                       | 60 s                       | 60 s                       |
| query mode                                | simple                     | simple                     | simple                     | extended                   | extended                   | extended                   |
| number of transactions actually processed | 85195                      | 85201                      | 85612                      | 84683                      | 83250                      | 84769                      |
| number of failed transactions             | 0                          | 0                          | 0                          | 0                          |                            |                            |
| latency average                           | 14.085 ms                  | 14.085 ms                  | 14.017 ms                  | 14.171 ms                  | 14.415 ms                  | 14.156 ms                  |
| initial connection time                   | 13.090 ms                  | 13.382 ms                  | 13.885 ms                  | 13.192 ms                  | 12.878 ms                  | 14.186 ms                  |
| tps (without initial connection time)     | 1419.90739                 | 1419.951538                | 1426.873706                | 1411.328009                | 1387.438167                | 1412.782948                |

### 3. Настроить на оптимальную производительность <a name="optimal_config"></a>

### 4. Настроить на оптимальную производительность, не обращая внимание на ACID <a name="extreme_fast_conig"></a>
