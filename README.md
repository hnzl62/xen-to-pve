XenServer to Proxmox Migration Script

This is a modified version of the XenServer to Proxmox migration script, with specific adjustments for use with NFS storage in Proxmox. The script automates the migration of virtual machine (VM) disks from XenServer to Proxmox by exporting the disks and recreating them on the specified NFS storage backend in Proxmox.

Features

	•	Supports NFS storage in Proxmox.
	•	Dynamically accepts the Proxmox storage backend as an argument for flexibility.
	•	Uses the xcp-xe tool to export disks from XenServer.
	•	Verifies and migrates each disk from XenServer to Proxmox using Proxmox’s storage system.

Prerequisites

1. xcp-xe Tool

The script requires the xcp-xe tool to interact with XenServer. You can download the required version from the following repository:

	•	Download xcp-xe_1.3.2-5ubuntu1_amd64.deb

Once downloaded, install it on the machine where you are running the script using:

sudo dpkg -i xcp-xe_1.3.2-5ubuntu1_amd64.deb

2. stunnel Installation

The script also requires stunnel for secure communications. You can install it using the following command:

sudo apt install stunnel

Usage

Script Invocation

To use the script, run it with the following arguments:

./migrate.sh <vm-uuid> <vm-id> <host> <port> <user> <pass> <storage>

	•	<vm-uuid>: The UUID of the VM on XenServer.
	•	<vm-id>: The VM ID in Proxmox.
	•	<host>: The IP address or hostname of the XenServer.
	•	<port>: The port to connect to on XenServer.
	•	<user>: The XenServer username (usually root).
	•	<pass>: The password for the XenServer user.
	•	<storage>: The Proxmox storage name where the disks should be created (e.g., nfs_storage).

Example

Here’s an example of how to run the script:

./migrate.sh 92dcc124-3baf-fa12-334a-d8aef0c85363 112 xcp01 443 root password nfs01

	•	This example migrates the VM with UUID 92dcc124-3baf-fa12-334a-d8aef0c85363 from the XenServer xcp01 (using port 443) to the Proxmox host, using the NFS storage nfs01.

Modifications

This version of the script has been specifically modified to:

	•	Handle NFS storage in Proxmox, dynamically constructing the file paths for VM disk images on NFS.
	•	Accept the Proxmox storage name as an argument for greater flexibility in environments with multiple storage backends.

License

This script is licensed under the GPL, in accordance with the original author’s license. See the LICENSE file for details.
