#!/bin/bash
#
# (c) 2021 GUEST.it s.r.l. - Alessandro Corbelli
# License: GPL
#
# Sample usage:
# migrate.sh <vm-uuid> <vm-id> <host> <port> <user> <pass> <storage>
#
# Requirements: - XCP-XE: http://mirror.yy.duowan.com:63782/ubuntu/pool/universe/x/xen-api/xcp-xe_1.3.2-5ubuntu1_amd64.deb
#               - stunnel
# Modified by Jan Andel in 2024 for XCP 8.2 and PVE 8.2
# this version is intended for use with NFS Storage

XS_HOST="$3"
XS_PORT="$4"
XS_USER="$5"
XS_PASS="$6"
STORAGE="$7"  # New argument for the storage name

XE_CMD="xe -s ${XS_HOST} -p ${XS_PORT} -u ${XS_USER} -pw ${XS_PASS}"

VM_UUID="$1"
VM_ID="$2"

if [ -z "${VM_UUID}" ] || [ -z "${VM_ID}" ] || [ -z "${STORAGE}" ]; then
   echo "Usage: $0 <vm-uuid> <vm-id> <host> <port> <user> <pass> <storage>"
   exit
fi

echo "Starting migration of XenServer \"${VM_UUID}\" to ProxMox #${VM_ID} using storage \"${STORAGE}\""

# Fetch remote disks
CNT=0
for LINE in $(${XE_CMD} vm-disk-list vdi-params="uuid,virtual-size" uuid=${VM_UUID} vbd-params="device" | cut -d':' -f2 | tr -d '\n\n' | cut -d' ' -f2- | tr ' ' ':' | sed -e 's/:/\n/3' -e 'P;D'); do

   echo ${LINE}

   DEVICE=$(echo ${LINE} | cut -d':' -f1)
   UUID=$(echo ${LINE} | cut -d':' -f2)
   SIZE=$(echo ${LINE} | cut -d':' -f3)

   if [ ${SIZE} -lt 1073741824 ]; then
      SIZE_GB=1
   else
      SIZE_GB=$(expr ${SIZE} / 1024 / 1024 / 1024)
   fi

   echo "Exporting device ${DEVICE} with UUID ${UUID}. Size=${SIZE_GB}. Disk #${CNT}"

   # Create disk on specified Proxmox storage
   qm set ${VM_ID} -virtio${CNT} ${STORAGE}:${SIZE_GB},cache=writeback

   DISK_NAME=$(grep "^virtio${CNT}:" /etc/pve/qemu-server/${VM_ID}.conf | cut -d':' -f3 | cut -d',' -f1)
   if [ -z "${DISK_NAME}" ]; then
      echo "qemu disk name not found in Proxmox configuration."
      exit
   fi

   # Adjusting file path for the specified storage
   BLOCK_DEVICE="/mnt/pve/${STORAGE}/images/${DISK_NAME}"

   # Verify disk file existence for the specified storage
   if ! [ -f "${BLOCK_DEVICE}" ]; then
      echo "Disk file not found at: ${BLOCK_DEVICE}"
      exit
   fi

   # Migrate the disk data from XenServer to Proxmox
   echo "Migrating data to ${BLOCK_DEVICE}"
   wget --http-user=${XS_USER} --http-password=''${XS_PASS}'' "http://${XS_HOST}/export_raw_vdi?vdi=${UUID}&format=raw" -q -O - | dd of=${BLOCK_DEVICE} bs=1M status=progress

   let CNT=CNT+1
done