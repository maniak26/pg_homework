#!/bin/bash

# Установить и настроить yandex-cli https://cloud.yandex.ru/ru/docs/cli/operations/install-cli

# Основные параметры ВМ
PG_VERSION=15
INSTANCE_NAME=pg15
SSH_KEY=${HOME}/.ssh/id_ed25519.pub
RAM=16 
CPU=8
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
