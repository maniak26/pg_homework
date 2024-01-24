# Домашнаяя работа №1

## Задача

1. [Развернуть ПГ любым удобным способом на Линукс](#install)
2. [Провести первичный бенчмарк (простой и расширеный варианты)](#reference_benchmark)
3. [Настроить на оптимальную производительность](#optimal_config)
4. [Настроить на максимальную производительнотсь, не обращая внимание на ACID](#extreme_fast_conig)
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

Вкюлчает в себя обновление всех существующих пакетов с ребоутом ВМ и установки ряда базовых пракетов. Выполняетс [плейбуком ansible](https://github.com/maniak26/pg_homework/blob/main/ansible/0_base_config.yml)

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

### 2. Провести первичный бенчмарк (простой и расширеный варианты) <a name="reference_benchmark"></a>

### 3. Настроить на оптимальную производительность <a name="optimal_config"></a>

### 4. Настроить на оптимальную производительнотсь, не обращая внимание на ACID <a name="extreme_fast_conig"></a>
