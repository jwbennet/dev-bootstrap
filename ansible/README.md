The files contained in this sub-directory are a collection of Ansible roles which are used to setup an Ubuntu OS based in WSL. This also installs all of the software necessary for a basic develop setup in that environment.

## Setup/Installation

1. Update the Apt repositories and perform a distribution upgrade if needed. This will ensure we're using the latest dependencies. This step will also ensure Python 3 has been installed which is a prerequisite for installing Ansible. After Python is installed this will install Ansible in the user context so we can use it across every project we maintain.
    ```bash
    sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y python3 python-is-python3 python3-pip && sudo apt install software-properties-common && sudo add-apt-repository --yes --update ppa:ansible/ansible && sudo apt install -y ansible && sudo mkdir -p /projects
    ```
1. This uses privileged access so it can install system-wide packages and configure the WSL instance appropriately.
    ```bash
    sudo ansible-playbook --extra-vars='wsl_username=$(whoami)' main.yaml
    ```
1. Finally we run the `user.yaml` playbook to install the software which is managed in our home directory
    ```bash
    ansible-playbook user.yaml
    ```
