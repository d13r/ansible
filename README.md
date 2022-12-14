# My Ansible Provisioner for Ubuntu Servers

This repo contains a playbook that I use to provision my Ubuntu servers (development and production).

## Setup

Install Ansible:

```bash
sudo add-apt-repository ppa:ansible/ansible
sudo apt install ansible
```

Clone the repo:

```bash
git clone git@github.com:d13r/ansible.git
cd ansible
vim vault-password.txt
```

Enter the vault password and save the file.

## Usage

### Test

Test connections to all servers:

```bash
ansible all -m ping
```

Print variables for a specific server:

```bash
ansible <host> -m setup
```

### Playbooks

Run the provisioner on all servers:

```bash
ansible-playbook provision.yml
```

Run the provisioner on a specific group or a single host:

```bash
ansible-playbook provision.yml -l dev
ansible-playbook provision.yml -l kara
```

Run tasks with a specific tag (or multiple tags):

```bash
ansible-playbook provision.yml -t dev
ansible-playbook provision.yml -t install
ansible-playbook provision.yml -t 'dev,&install' # Only tasks with both 'dev' and 'install'

# To check the available tags:
ansible-playbook provision.yml --list-tags
```

### Running ad hoc commands

Start the interactive console:

```bash
ansible-console

# Select a subset of servers (a group or a single host)
ansible-console dev
ansible-console kara
```

Switch group/host interactively:

```bash
cd dev
cd kara
cd all
```

List the servers that are currently selected:

```bash
list
```

Run an arbitrary shell command on all/selected servers:

```bash
# The `!` is technically optional here, but if the command conflicts with a module name (e.g. `apt`) then the module will be executed instead of the command
!echo "Test"
```

Uninstall a package (or multiple) from all/selected servers:

```bash
apt name=example1,example2 state=absent
snap name=example1,example2 state=absent
```

Delete a file/directory from all/selected servers:

```bash
file path=/example state=absent
```

Reboot (and wait for each server to come back up):

```bash
reboot
```

Commands can also be run directly from Bash, rather than using Ansible console:

```bash
ansible all -m shell -a 'echo "Test"'
ansible all -m apt -a 'name=example1,example2 state=absent'
ansible all -m snap -a 'name=example1,example2 state=absent'
ansible all -m file -a 'path=/example state=absent'
ansible all -m reboot
```

Replace `all` with a group or host name if required.

### Passwords

Edit a passwords file:

```bash
ansible-vault edit host_vars/<host>/passwords.yml
```

Change the vault password:

```bash
ansible-vault rekey --ask-vault-password host_vars/*/passwords.yml
```

## Setting up a new production VM

Create the VM and the required DNS records. I [use Terraform](https://github.com/d13r/terraform/blob/4e3ce38a2f913077590511d94c846bc3ef55e67f/vm-summer.tf) for this.

Add the server to `hosts.ini` and `host_vars/`, then run:

```bash
ansible-playbook provision.yml -l <host>
```

The provisioner is idempotent, so it can be run repeatedly if there are any problems.

## Setting up a new local VM

Install Hyper-V and [Multipass](https://multipass.run/).

Create a new Hyper-V internal network, so the VM can be given a static IP address:

- Open Hyper-V Manager
- Go to Action > Virtual Switch Manager
- In "New virtual network switch", select "Internal" and click "Create Virtual Switch"
- Set the name to "Hyper-V Internal Network"
- Click OK.
- Go to Start > View network connections
- Right-click "vEthernet (Hyper-V Internal Network)" > Properties
- Select "Internet Protocol Version 4" and click Properties
- Select "Use the following IP address"
- Enter the IP `192.168.5.1`, or another IP of your choice
- Click OK, then Close

Launch WSL and run:

```bash
# This is in my dotfiles:
alias multipass=multipass.exe

# Check the new network is listed
multipass networks

# Adjust this with the required version, name and resources
multipass launch 22.04 --name <host> --cpus 8 --mem 16G --disk 100G --network "name=Hyper-V Internal Network"

# Connect to the VM
multipass shell <host>
```

Add my SSH key:

```bash
echo 'ssh-rsa AAAA...Nd5w== d@djm.me' > ~/.ssh/authorized_keys
```

Set an IP address for the extra network, and also override the DNS server because some networks block hostnames that resolve to local IP addresses:

```bash
sudo vim /etc/netplan/90-custom.yaml
```

```yaml
network:
  ethernets:
    eth0:
      nameservers: # Override DNS
        addresses:
          - 1.1.1.1
          - 1.0.0.1
    eth1:
      addresses:
        - 192.168.5.3/24 # Static IP (make sure this is unique for each VM)
  version: 2
```

Run:

```bash
sudo netplan apply
```

**Note:** `netplan try` results in the connection freezing, then it eventually rolls back automatically. `netplan apply` also results in the connection freezing, but then you can reconnect fine.

Create DNS records (I [use Terraform](https://github.com/d13r/terraform/blob/771ea531b050645a0a6ae2b92cd0a0044d320f3a/vm-kara.tf) for this):

| Hostname          | Type  | Value                                                       |
|-------------------|-------|-------------------------------------------------------------|
| `<host>.djm.me`   | A     | `192.168.1.3`                                               |
| `<host>.djm.me`   | TXT   | `v=spf1 include:spf.messagingengine.com a:home.djm.me -all` |
| `*.<host>.djm.me` | CNAME | `<host>.djm.me`                                             |

Now it should be possible to connect from WSL using SSH instead of `multipass shell`:

```bash
ssh ubuntu@<host>.djm.me
```

Now use Ansible to install everything. Add the server to `hosts.ini` and `host_vars/`, then run:

```bash
ansible-playbook provision.yml -l <host>
```
