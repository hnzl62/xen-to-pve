# XenServer to Proxmox Migration Script

This is a modified version of the XenServer to Proxmox migration script, with specific adjustments for use with NFS storage in Proxmox. The script automates the migration of virtual machine (VM) disks from XenServer to Proxmox by exporting the disks and recreating them on the specified NFS storage backend in Proxmox.

## Features
- Supports NFS storage in Proxmox.
- Dynamically accepts the Proxmox storage backend as an argument for flexibility.
- Uses the `xcp-xe` tool to export disks from XenServer.
- Verifies and migrates each disk from XenServer to Proxmox using Proxmox’s storage system.

## Prerequisites

### 1. xcp-xe Tool
The script requires the `xcp-xe` tool to interact with XenServer. You can download the required version from the following repository:

[https://github.com/hnzl62/xen-to-pve/blob/master/xcp-xe_1.3.2-5ubuntu1_amd64.deb](https://github.com/hnzl62/xen-to-pve/blob/master/xcp-xe_1.3.2-5ubuntu1_amd64.deb)

Once downloaded, install it on the machine where you are running the script using:

    sudo dpkg -i xcp-xe_1.3.2-5ubuntu1_amd64.deb

### 2. stunnel Installation
The script also requires `stunnel` for secure communications. You can install it using the following command:

    sudo apt install stunnel

## Usage

### Script Invocation
To use the script, run it with the following arguments:

    ./migrate.sh <vm-uuid> <vm-id> <host> <port> <user> <pass> <storage>

- `<vm-uuid>`: The UUID of the VM on XenServer.
- `<vm-id>`: The VM ID in Proxmox.
- `<host>`: The IP address or hostname of the XenServer.
- `<port>`: The port to connect to on XenServer.
- `<user>`: The XenServer username (usually root).
- `<pass>`: The password for the XenServer user.
- `<storage>`: The Proxmox storage name where the disks should be created (e.g., nfs_storage).

### Example

Here’s an example of how to run the script:

    ./migrate.sh 92dcc124-3baf-fa12-334a-d8aef0c85363 112 xcp01 443 root password nfs01

- This example migrates the VM with UUID `92dcc124-3baf-fa12-334a-d8aef0c85363` from the XenServer `xcp01` (using port `443`) to the Proxmox host, using the NFS storage `nfs01`.

## Modifications

This version of the script has been specifically modified to:
- Handle NFS storage in Proxmox, dynamically constructing the file paths for VM disk images on NFS.
- Accept the Proxmox storage name as an argument for greater flexibility in environments with multiple storage backends.

## License
This script is licensed under the GPL, in accordance with the original author’s license. See the `LICENSE` file for details.


# Migration Steps from Xen/XCP to Proxmox

1. **Take VM Snapshot on Xen/XCP**

   - In case things go sideways, take a snapshot of the VM on Xen or XCP.

2. **Remove Xen/XCP/Citrix Programs**

   - On the VM, go to **Add or Remove Programs**.
   - Search for any programs related to **xen**, **xcp**, or **citrix** and uninstall everything you can find.

3. **Delete Xen Files via CMD**

   - Launch an administrative Command Prompt and run the following command:

     ```cmd
     del /F /Q C:\Windows\System32\xen*
     ```

4. **Run XCP-ng Windows Guest Tools Cleaner**

   - Download and run the [XCP-ng Windows Guest Tools Cleaner](https://github.com/xcp-ng/xcp/files/2923646/XCP-ng-Windows-Guest-Tools-Cleaner_alpha.zip).
   - The result must be **"No Leftover XenDrivers"**.

5. **Install VirtIO Drivers and QEMU Guest Agent**

   - Install VirtIO drivers from [virtio-win-gt-x64.msi](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.262-2/virtio-win-gt-x64.msi).
   - Install QEMU Guest Agent from [virtio-win-guest-tools.exe](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.262-2/virtio-win-guest-tools.exe).

6. **Ensure Local Admin Password is Known**

   - Make sure you know the local administrator password; you will need it.

7. **Shutdown the VM**

   - Properly shut down the VM.

8. **Take Note of VM UUID in Xen**

   - Obtain and record the VM UUID from Xen.

9. **Create New VM in Proxmox**

   - Create a new VM in Proxmox with the following settings:
     - **Guest Type**: Windows
     - **Guest Tools**: Select that guest tools are installed
     - **BIOS/UEFI**: Select the correct BIOS/UEFI setting
     - **Disks**: Do not attach any disks
     - **Network Card**: Set as disconnected

10. **Take Note of the VM ID**

    - Record the VM ID assigned in Proxmox.

11. **Initiate Migration**

    - Login to the Proxmox host via SSH.
    - Navigate to:

      ```bash
      cd /mnt/pve/YOURNFSSHARE
      ```

    - Copy the migrate.sh there and launch the migration command based on your Xen VM UUID and Proxmox VM ID:

      ```bash
      ./migrate.sh XENVMUUID PROXMOXVMID SOURCEXENHOSTFQDN 443 root XENROOTPASSWORD
      ```

    - This will initiate the migration of the VHDX to a RAW disk image for Proxmox.
    - At the end, you should see something like this:

      ```
      Starting migration of XenServer "92dcc124-3baf-fa12-334a-d8aef0c85363" to ProxMox #112
      xvda:73ea7ece-9b39-4761-a2e4-b3a2cf7046d9:106300440576
      Exporting device xvda with UUID 73ea7ece-9b39-4761-a2e4-b3a2cf7046d9. Size=99. Disk #0
      update VM 112: -virtio0 YOURNFSSHARE:99,cache=writeback
      Formatting '/mnt/pve/YOURNFSSHARE/images/112/vm-112-disk-3.raw', fmt=raw size=106300440576 preallocation=off
      virtio0: successfully created disk 'YOURNFSSHARE:112/vm-112-disk-3.raw,cache=writeback,size=99G'
      Migrating on /mnt/pve/YOURNFSSHARE/images/112/vm-112-disk-3.raw
      106259652144 bytes (106 GB, 99 GiB) copied, 2331 s, 45.6 MB/s
      0+9788652 records in
      0+9788652 records out
      106300440576 bytes (106 GB, 99 GiB) copied, 2336.52 s, 45.5 MB/s
      ```

12. **Configure VM in Proxmox**

    - In Proxmox, ensure that in the VM options:
      - The restored disk is added as the **boot option**.
      - The disk is mounted as **SATA**.

13. **Boot VM in Repair Mode**

    - Boot the VM in repair mode by spamming the **F8 key** during boot.

14. **Remove Xen Drivers via Recovery Mode**

    - In Recovery mode, run the following commands:

      ```cmd
      X:\> dism /Image:D:\ /Get-Drivers
      ```

      - Then look for the Xen drivers—they'll be listed as something like `oem6.inf`, etc.
      - Remove them with:

      ```cmd
      X:\> dism /Image:D:\ /Remove-Driver /Driver:oem6.inf
      ```

      - Repeat this for all entries in `Get-Drivers` that mention **Xen**.

15. **Shutdown the VM**

    - After removing the drivers, shut down the VM.

16. **Attach Temporary VirtIO Disk**

    - Attach a small (10 GB) **VirtIO** disk to the VM to ensure VirtIO drivers are loaded.

17. **Power On the VM**

    - Power on the VM in Proxmox.
    - Verify it boots and test the local admin account.
    - Make sure you can see the VirtIO disk.

18. **Remove Temporary VirtIO Disk**

    - Power down the VM.
    - Remove the temporary VirtIO disk.

19. **Reattach the SATA Disk as VirtIO**

    - Detach the SATA disk.
    - Reattach it as **VirtIO**.
    - Enable the **Discard** checkbox.
    - Ensure to set it again as the boot device in Proxmox VM options.

20. **Reconnect the Network Adapter**

    - If everything looks OK, reconnect the network adapter.

21. **Migrate VM to Other NFS Storage**

    - Migrate the VM to other NFS storage to convert the disk from `.raw` to `.qcow2` in the process.

22. **Add VM to PBS Backup (If Needed)**

    - If needed, add the VM to the Proxmox Backup Server.

23. **Disable or Remove VM in Xen**

    - Ensure the VM in Xen has its network adapter disconnected or is removed.