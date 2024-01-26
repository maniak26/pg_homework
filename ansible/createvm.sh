#!/bin/bash

# Установить и настроить yandex-cli https://cloud.yandex.ru/ru/docs/cli/operations/install-cli

# Основные параметры ВМ
# Версия ПГ
PG_VERSION=15
# Имя инстанса
INSTANCE_NAME=pg15
# Откуда брать SSH ключ
SSH_KEY=${HOME}/.ssh/id_ed25519.pub
# Число ядер
CPU=8
# Объем ОЗУ
RAM=16


# За кадром, не вынесено в параметры:
# --core-fraction 100 - процент доступности процессора. Т.к. собираемся тесты производительности делать, надо исключить внешние факторы
#
# --create-boot-disk 'image-family=ubuntu-2204-lts,size=93,type=network-ssd-nonreplicated,auto-delete' \
# ОС ubuntu-2204-lts
# размер 93 Гб (должно хватить с лихвой. Не круглое число - требование network-ssd-nonreplicated диска)
# network-ssd-nonreplicated - нереплицируемый SSD диск. Пойдет для тестов т.к. цена потери данных = перезаливка заново скриптами базы
# auto-delete - чтоб удалялся вместе с ВМ
#
# --preemptible - отключаемая ВМ (работает не больше суток, могут в любой момент вырубить) - экономим деньги

# Создать ВМ
yc compute instance create \
--name ${INSTANCE_NAME} \
--description ${INSTANCE_NAME} \
--hostname ${INSTANCE_NAME} \
--create-boot-disk 'image-family=ubuntu-2204-lts,size=93,type=network-ssd-nonreplicated,auto-delete' \
--image-folder-id standard-images \
--memory ${RAM} \
--cores ${CPU} \
--core-fraction 100 \
--ssh-key ${SSH_KEY} \
--public-ip \
--preemptible 
# \
# --async

# Получить ее IP
IP=$(yc compute instance get --name ${INSTANCE_NAME} --format json | jq -r '.network_interfaces.[].primary_v4_address.one_to_one_nat.address')
# закинуть в hosts.ini
echo "${INSTANCE_NAME} ansible_host=${IP} postgresql_version=${PG_VERSION}" >> hosts.ini
