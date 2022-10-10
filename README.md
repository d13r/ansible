# Ansible Provisioner

## Usage

```bash
git clone git@github.com:d13r/ansible.git
cd ansible

sudo add-apt-repository ppa:ansible/ansible
sudo apt install ansible

ansible-playbook debug.yml -l <host>
ansible-playbook provision.yml
```
