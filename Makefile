SHELL:=/bin/bash
DOCKER_SLAVE_URL := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^docker_slave_host_url" | awk '{ print $$2 }')
DOCKER_SLAVE_IP_ADDRESS := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^docker_slave_ip_address" | awk '{ print $$2 }')
JENKINS_MASTER_URL := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^jenkins_master_host_url" | awk '{ print $$2 }')
JENKINS_MASTER_IP_ADDRESS := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^jenkins_master_ip_address" | awk '{ print $$2 }')
WINDOWS_RUST_SLAVE_URL := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^windows_rust_slave_host_url" | awk '{ print $$2 }')
WINDOWS_RUST_SLAVE_IP_ADDRESS := $(shell cat environments/vagrant/group_vars/all/vars.yml | grep "^windows_rust_slave_ip_address" | awk '{ print $$2 }')

box-base-windows-2012_r2-vbox:
	if [ ! -d "packer_output" ]; then mkdir packer_output; fi
	if [ -f "packer_output/base-windows-2012_r2-x86_64.box" ]; then rm packer_output/base-windows-2012_r2-x86_64.box; fi
	packer validate templates/base-windows-2012_r2-virtualbox-x86_64.json
	packer build templates/base-windows-2012_r2-virtualbox-x86_64.json

box-base-windows-2016-vbox:
	if [ ! -d "packer_output" ]; then mkdir packer_output; fi
	if [ -f "packer_output/base-windows-2016-virtualbox-x86_64.box" ]; then rm packer_output/base-windows-2016-virtualbox-x86_64.box; fi
	packer validate templates/base-windows-2016-virtualbox-x86_64.json
	packer build templates/base-windows-2016-virtualbox-x86_64.json

box-travis_slave-windows-2016-vbox:
	if [ ! -d "packer_output" ]; then mkdir packer_output; fi
	if [ -f "packer_output/travis_slave-windows-2016-virtualbox-x86_64.box" ]; then rm packer_output/travis_slave-windows-2016-virtualbox-x86_64.box; fi
	packer validate templates/travis_slave-windows-2016-virtualbox-x86_64.json
	packer build templates/travis_slave-windows-2016-virtualbox-x86_64.json

box-docker_slave-centos-7.6-x86_64-aws:
	packer validate templates/docker_slave-centos-7.6-aws-x86_64.json
	EC2_INI_PATH=/etc/ansible/ec2.ini packer build templates/docker_slave-centos-7.6-aws-x86_64.json

vm-jenkins_master-centos-7.6-x86_64-vbox: export JENKINS_MASTER_IP_ADDRESS := ${JENKINS_MASTER_IP_ADDRESS}
vm-jenkins_master-centos-7.6-x86_64-vbox: export JENKINS_MASTER_URL := ${JENKINS_MASTER_URL}
vm-jenkins_master-centos-7.6-x86_64-vbox:
	vagrant up jenkins_master-centos-7.6-x86_64 --provision

vm-rust_slave-centos-7.6-x86_64-vbox:
	vagrant up rust_slave-centos-7.6-x86_64 --provision

vm-rust_slave-ubuntu-trusty-x86_64-vbox:
	vagrant up rust_slave-ubuntu-trusty-x86_64 --provision

vm-docker_slave-centos-7.6-x86_64-vbox: export DOCKER_SLAVE_IP_ADDRESS := ${DOCKER_SLAVE_IP_ADDRESS}
vm-docker_slave-centos-7.6-x86_64-vbox: export DOCKER_SLAVE_URL := ${DOCKER_SLAVE_URL}
vm-docker_slave-centos-7.6-x86_64-vbox:
	vagrant up docker_slave-centos-7.6-x86_64 --provision

vm-base-windows-2012_r2-x86_64-vbox:
	vagrant up base-windows-2012_r2-x86_64 --provision

vm-rust_slave_git_bash-windows-2012_r2-x86_64-vbox:
	vagrant up rust_slave_git_bash-windows-2012_r2-x86_64 --provision

vm-rust_slave_msys2-windows-2012_r2-x86_64-vbox:
	vagrant up rust_slave_msys2-windows-2012_r2-x86_64 --provision

vm-jenkins_rust_slave-windows-2016-x86_64-vbox: export OBJC_DISABLE_INITIALIZE_FORK_SAFETY := YES
vm-jenkins_rust_slave-windows-2016-x86_64-vbox: export JENKINS_MASTER_IP_ADDRESS := ${JENKINS_MASTER_IP_ADDRESS}
vm-jenkins_rust_slave-windows-2016-x86_64-vbox: export JENKINS_MASTER_URL := ${JENKINS_MASTER_URL}
vm-jenkins_rust_slave-windows-2016-x86_64-vbox: export WINDOWS_RUST_SLAVE_IP_ADDRESS := ${WINDOWS_RUST_SLAVE_IP_ADDRESS}
vm-jenkins_rust_slave-windows-2016-x86_64-vbox: export WINDOWS_RUST_SLAVE_URL := ${WINDOWS_RUST_SLAVE_URL}
vm-jenkins_rust_slave-windows-2016-x86_64-vbox:
	vagrant up jenkins_rust_slave-windows-2016-x86_64 --provision

vm-travis_rust_slave-windows-2016-x86_64-vbox:
	vagrant up travis_rust_slave-windows-2016-x86_64 --provision

env-jenkins-dev-vbox: export DOCKER_SLAVE_IP_ADDRESS := ${DOCKER_SLAVE_IP_ADDRESS}
env-jenkins-dev-vbox: export DOCKER_SLAVE_URL := ${DOCKER_SLAVE_URL}
env-jenkins-dev-vbox: export JENKINS_MASTER_IP_ADDRESS := ${JENKINS_MASTER_IP_ADDRESS}
env-jenkins-dev-vbox: export JENKINS_MASTER_URL := ${JENKINS_MASTER_URL}
env-jenkins-dev-vbox: \
	vm-docker_slave-centos-7.6-x86_64-vbox \
	vm-jenkins_master-centos-7.6-x86_64-vbox \
	vm-jenkins_rust_slave-windows-2016-x86_64-vbox
	vagrant reload jenkins_rust_slave-windows-2016-x86_64

env-jenkins-dev-aws:
	./scripts/install_external_java_role.sh
	cd terraform/dev && terraform init && terraform apply -auto-approve
	@echo "Sleep for 3 minutes to allow SSH to become available and yum updates on Linux instances..."
	@sleep 180
	@echo "Attempting Ansible run against Docker slaves...(can be 10+ seconds before output)"
	rm -rf ~/.ansible/tmp
	EC2_INI_PATH=/etc/ansible/ec2.ini ansible-playbook -i environments/dev \
		--vault-password-file=~/.ansible/vault-pass \
		--private-key=~/.ssh/jenkins_env_key \
		-e "cloud_environment=dev" \
		-u centos ansible/docker-slave.yml
	@echo "Attempting Ansible run against Jenkins master...(can be 10+ seconds before output)"
	rm -rf ~/.ansible/tmp
	EC2_INI_PATH=/etc/ansible/ec2.ini ansible-playbook -i environments/dev \
		--limit=jenkins_master \
		--vault-password-file=~/.ansible/vault-pass \
		--private-key=~/.ssh/jenkins_env_key \
		-e "cloud_environment=dev" \
		-u ubuntu ansible/jenkins-master.yml
	#./scripts/sh/run_ansible_against_mac_slave.sh
	./scripts/sh/run_ansible_against_windows_instance.sh

env-jenkins-prod-aws:
ifeq ($(DEBUG_JENKINS_ENV),true)
	cd terraform/prod && terraform init && terraform apply -auto-approve -var-file=debug.tfvars
else
	cd terraform/prod && terraform init && terraform apply -auto-approve
endif
	rm -rf ~/.ansible/tmp
	echo "Sleep for 2 minutes to allow yum update to complete"
	sleep 120
	EC2_INI_PATH=/etc/ansible/ec2.ini ansible-playbook -i environments/prod \
		--vault-password-file=~/.ansible/vault-pass \
		--private-key=~/.ssh/ansible \
		-e "safe_build_infrastructure_repo_owner=maidsafe" \
		-e "safe_build_infrastructure_repo_branch=master" \
		-u ansible ansible/ansible-provisioner.yml

provision-jenkins-prod-aws:
ifndef JENKINS_WINDOWS_SLAVE_PASSWORD
	@echo "The JENKINS_WINDOWS_SLAVE_PASSWORD variable must be set."
	@exit 1
endif
ifndef JENKINS_MASTER_HOSTNAME
	@echo "The JENKINS_MASTER_HOSTNAME variable must be set."
	@exit 1
endif
ifndef SLAVE_SUBNET_ID
	@echo "The SLAVE_SUBNET_ID variable must be set."
	@exit 1
endif
	./scripts/install_external_java_role.sh
	rm -rf ~/.ansible/tmp
	EC2_INI_PATH=/etc/ansible/ec2.ini ansible-playbook -i environments/prod \
		--limit=jenkins_master \
		--vault-password-file=~/.ansible/vault-pass \
		-e "cloud_environment=true" \
		-e "slave_vpc_subnet_id=${SLAVE_SUBNET_ID}" \
		-u ansible ansible/jenkins-master.yml
	./scripts/sh/run_ansible_against_prod_windows_instance.sh

provision-rust_slave-macos-mojave-x86_64:
	# Pipelining must be enabled to get around a problem with permissions and temporary files on OSX:
	# https://docs.ansible.com/ansible/latest/user_guide/become.html#becoming-an-unprivileged-user
	ANSIBLE_PIPELINING=True ansible-playbook -i environments/vagrant/hosts ansible/osx-rust-slave.yml

clean-rust_slave-macos-mojave-x86_64:
	ANSIBLE_PIPELINING=True ansible-playbook -i environments/vagrant/hosts ansible/osx-teardown.yml

clean-vbox:
	./scripts/sh/destroy_local_vms.sh

clean-jenkins-dev-aws:
	cd terraform/dev && terraform destroy

clean-jenkins-prod-aws:
	cd terraform/prod && terraform destroy
