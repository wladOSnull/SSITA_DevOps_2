# Geo Citizen

## Manual infrastructure

### AWS prepare

Default t2.micro instance type ins not enough for running Geo Citien application. To get t3.micro **FREE TIER** instance you must change region to *eu-noth-1* a.k.a. *Stockholm*.  
Also you must change default region for aws CLI in *~/.aws/config* file:

- changing default region for aws CLI

  ```bash
  ~ nano ~/.aws/config
  ```

  ```md
  # text to write:

  [default]
  region = eu-north-1
  ```

Creating + importing SSH key pairs for Ubuntu instances:

>*IMPORTANT*: there must be already AWS account with IAM identity and *.aws* folder in home directory with credentials of the IAM identity **+** *config* file with setted region

- creating SSH key pairs

  ```bash
  # separate folder for Ubuntu Instance SSH key pairs
  ~ cd ~/.aws
  ~ mkdir ssh_ubuntu
  ~ cd ssh_ubuntu

  # create SSH pair for Ubuntu instance
  ~ ssh-keygen -t rsa -b 4096 -C "wlad1324@gmail.com" -f ~/.aws/ssh_ubuntu/id_rsa
  type pass
  type pass
  ~ ls -la

  # separate folder for CentOS Instance SSH key pairs
  ~ ~ cd ~/.aws
  ~ mkdir ssh_centos
  ~ cd ssh_centos

  # create SSH pair for Ubuntu instance
  ~ ssh-keygen -t rsa -b 4096 -C "wlad1324@gmail.com" -f ~/.aws/ssh_centos/id_rsa
  type pass
  type pass
  ~ ls -la
  ```

- importing public SSH keys to AWS account

  ```bash
  # import SSH key for Ubuntu to AWS account
  ~ aws ec2 import-key-pair --key-name "id_rsa_ubuntu" --public-key-material file://~/.aws/ssh_ubuntu/id_rsa.pub

  # import SSH key for CentOS to AWS account
  ~ aws ec2 import-key-pair --key-name "id_rsa_centos" --public-key-material file://~/.aws/ssh_centos/id_rsa.pub

  ```

### Ubuntu Instance

- create EC2 instance
  - [youtube](https://www.youtube.com/watch?v=yPdmy--Uh50)
    - on *Step 1: Choose an Amazon Machine Image (AMI)* select *Quick Start* group and search for *ubuntu*, select *Ubuntu Server 20.04 LTS* and move on with video guide
    - also **ADD** 8080 port for Tomcat in "Configure security group" and private IP of only YOUR host PC for SSH !!! (for security)  

- allocate new EIP  
  - [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

- associate EIP for the Ubuntu instance
  - [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

- get a SSH connection string for instance 
  - *Connect* button -> *SSH client* -> *Example:*

- *OPTIONAL*: add SSH connection alias to *config* file in *~/.ssh* folder

  ```bash
  # on host
  ~ nano ~/.ssh/config
  ```

  ```md
  # text to write:

  Host awsUbuntu
    User ubuntu
    HostName ec2-<EIP-of-Ubuntu-instance>.eu-north-1.compute.amazonaws.com
    Port 22
    IdentityFile ~/.aws/ssh_ubuntu/id_rsa
  ```  

- connect to instance via SSH from host

  ```bash
  ~ ssh awsUbuntu
  # type passphrase (if you setted this one)
  ```

- perform all steps from *Runbook Geocitizen.md* - Ubuntu Server chapter **WITHOUT** *OPTIONAL* sections

- try to visit Tomcat start page

### CentOS Instance

- create EC2 instance
  - [youtube](https://www.youtube.com/watch?v=yPdmy--Uh50)
    - on *Step 1: Choose an Amazon Machine Image (AMI)* search for *ami-0358414bac2039369*, select *Community AIMs* group and select founded AMI then move on with video guide
    - also **ADD** 5432 port + EIP of Ubuntu Instance for PostgreSQL in "Configure security group" and private IP of only YOUR host PC for SSH !!! (for security)  

- allocate new EIP  
  - [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

- associate EIP for the Ubuntu instance
  - [AWS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)

- get a SSH connection string for instance 
  - *Connect* button -> *SSH client* -> *Example:*

- *OPTIONAL*: add SSH connection alias to *config* file in *~/.ssh* folder

  ```bash
  # on host
  ~ nano ~/.ssh/config
  ```

  ```md
  # text to write:

  Host awsCentOS
    User centos
    HostName ec2-<EIP-of-CentOS-instance>.eu-north-1.compute.amazonaws.com
    Port 22
    IdentityFile ~/.aws/ssh_centos/id_rsa
  ```  

- connect to instance via SSH from host

  ```bash
  ~ ssh awsCentOS
  # type passphrase (if you setted this one)
  ```

- perform all steps from *Runbook Geocitizen.md* - CentOS DB chapter
  - to run command as root use privileges eacalation

    ```bash
    ~ sudo su
    # now you are 'root'
    ```

  - this AMI doesn't contain *firewalld* so -> [itsectorforu](https://itsecforu.ru/2018/08/14/%D0%BA%D0%B0%D0%BA-%D0%B8%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D1%82%D1%8C-firewall-cmd-command-not-found-%D0%BE%D1%88%D0%B8%D0%B1%D0%BA%D1%83-%D0%B2-rhel-centos-7/)

- check access from Ubuntu instance to CentOS instance by

  ```bash
  ~ nc -vz <EIP-of-CentOS-instance> 5432
  ```

### Geo Citizen

After all previous steps you got  fully manual configured infrastructures (2 EC2 instances).
Now you have to deploy/configure Geo Citizen application:

- on CentOS instance

  ```bash
  ~ mkdir Donwload
  ~ cd Download

  ~ vi db.sh
  ~ i
  # copy-paste script for database configuration
  ~ Esc
  ~ :x

  ~ chmod u+x db.sh
  ~ ./db.sh
  ```

- on Ubuntu instance

  ```bash
  ~ mkdir Donwload
  ~ cd Download

  ~ nano project.sh
  # copy-paste script for Geo Citizen configuration
  ~ Ctrl+s
  ~ Ctrl+x

  ~ chmod u+x project.sh
  ~ ./project.sh
  ```

## Terraform


```bash
~ terraform init
~ terraform validate -json

~ terraform plan -out=plan
~ terraform apply plan
```

## Ansible

Reinstall Ansible 2.9.6 due to some bugs with *bash* or *shell* modules and performing CLI commands on guests.

  ```bash
  ~ sudo apt remove ansible

  ~ pip3 install ansible
  ~ pip3 install ansible-core==2.12.2
  ~ pip3 install ansible-base

  ~ ansible --version
  ```

Installing/configuring tools for dynamic inventory file -> [devopscube](https://devopscube.com/setup-ansible-aws-dynamic-inventory/)

- installing Ansible plugin boto3

  ```bash
  ~ pip3 install boto3
  ```

- plugin configuring

  ```bash
  ~ sudo mkdir -p /opt/ansible/inventory
  ~ cd /opt/ansible/inventory

  ~ sudo vi aws_ec2.yaml
  ```

  ```md
  # text to write:

  ---
  plugin: aws_ec2
  aws_access_key: <YOUR-AWS-ACCESS-KEY-HERE>
  aws_secret_key: <YOUR-AWS-SECRET-KEY-HERE>
  keyed_groups:
    - key: tags
      prefix: tag
  ```

- testing plugin

  ```bash
  ~ ansible-inventory -i /opt/ansible/inventory/aws_ec2.yaml --list
  ```

- this file can be created in any place but with name *aws_ec2* ! Add filter by *running*

  ```bash
  ~ nano ~/Documents/AWS/aws_ec2.yaml
  ```

  ```md
  # text to write

  ---

  plugin: aws_ec2
  aws_access_key: <YOUR-AWS-ACCESS-KEY-HERE>
  aws_secret_key: <YOUR-AWS-SECRET-KEY-HERE>
  keyed_groups:
    - key: tags
      prefix: tag
  filters:
    instance-state-name: running

  ...
  ```

- print some filtered/grouped hosts

  ```bash
  ~ ansible-inventory -i Documents/AWS/aws_ec2.yaml --graph
  ```

- ping certain host group from output 

  ```bash
  ~ ansible tag_Name_terraform_Ubuntu -m ping -i Documents/AWS/aws_ec2.yaml -u ubuntu --private-key=~/.aws/ssh_ubuntu/id_rsa
  ```

- example of runnig that hosts file

  ```bash
  ~ ansible-playbook main.yaml -i aws_ec2.yaml -u ubuntu --private-key=~/.aws/ssh_ubuntu/id_rsa
  ```

## Ansible Galaxy

Guide -> [youtube](https://www.youtube.com/watch?v=HEnVp84qVsc)

## Ansible Molecule

Guide1 -> [habr](https://habr.com/ru/post/527454/)
Guide2 -> [ansible](https://www.ansible.com/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1)

Also install addition packages:

  ```bash
  ~ pip3 install ansible-lint
  ~ pip3 install molecule-ec2
  ```

## Ansible AWX k3s

In my case there is *k3s* cluster with deployed *Operator* that deployed *Ansible AWX*:
- restoring *k3s* cluster after removing from autostart:

  ```bash
  - service k3s start
  ~ sudo chmod 644 /etc/rancher/k3s/k3s.yaml
  ~ kubectl get namespace
  ~ sudo kubectl config set-context --current --namespace=awx
  ~ kubectl get pod
  ```

- AWX web console on localhost:30621

Build own *awx-ee* -> [linkedin](https://www.linkedin.com/pulse/creating-custom-ee-awx-phil-griffiths/)
Problem with *docker push* -> [stackoverflow](https://stackoverflow.com/questions/33217658/docker-access-to-the-requested-resource-is-not-authorized)
Problem with *docker push* 2 -> [stackoverflow](https://stackoverflow.com/questions/36022892/how-to-know-if-docker-is-already-logged-in-to-a-docker-registry-server)
Rename of docker images -> [stackoverflow](https://stackoverflow.com/questions/25211198/docker-how-to-change-repository-name-or-rename-image)
Quay repositories of *awx-ee* -> [quay](https://docs.quay.io/guides/pushpull.html)
New type of credentials in AWX -> [unixarena](https://www.unixarena.com/2018/12/ansible-tower-awx-store-credential-custom-credentials-type.html/)
New type of credentials in AWX 2 !->[youtube](https://www.youtube.com/watch?v=yT5tMyEGEmU)
Passing variable between hosts/roles in one AWX Workflow -> [google](https://groups.google.com/g/awx-project/c/bOefHyZ4eIU)

## Ansible AWX Docker

Official installation guide for latest release-> [github](https://github.com/ansible/awx/blob/devel/tools/docker-compose/README.md)  

Another installation guide for older release -> [linuxtechi](https://www.linuxtechi.com/install-ansible-awx-on-ubuntu/)

## Appendix

Useful commands:

- check system info 

  ```bash
  ~ htop
  ```

- check free disk space

  ```bash
  ~ df -hT /
  ```

- check access from 1 instance to 2 instance by port

  ```bash
  ~ nc -vz <EIP-of-CentOS-instance> 5432
  ```

- copy local tarball to remote by *sct* and *ssh* alias

  ```bash
  ~ scp ../Documents/AWS/ansible_boto3.tar awsDevOps:/home/ec2-user
  ```

- copy remote tarball to local by *scp* and *ssh* alias

  ```bash
  ~ scp awsDevOps:/home/ec2-user/Documents/ball.tar /home/wlados/Documents/AWS/
  ```

- packing folder to tarball

  ```bash
  ~ tar -cvf terraform.tar terraform/
  ```

- listing tarball files

  ```bash
  ~ tar -tvf ball.tar

  # print only files that matchs 'pattern'
  ~ tar -tvf ball.tar '*.yaml'
  ```

- unpacking tarball

  ```bash
  ~ tar -xvf terraform.tar
  ```

Useful resources:

- guides:

  - change SSH key pair passphrase -> [cybercity](https://www.cyberciti.biz/faq/howto-ssh-changing-passphrase/)

  - list of CentOS AMIs -> [centos](https://wiki.centos.org/Cloud/AWS)

  - install *screenfetch* on CentOS -> [tanmaync](https://tanmaync.wordpress.com/2017/10/02/install-screenfetch-centos7-rhel7/)

  - install *htop* on CentOS -> [cheapwindowsvps](https://cheapwindowsvps.com/blog/how-to-install-htop-on-centos-7/)

  - install *firewalld* on CentOS -> [itsectorforu](https://itsecforu.ru/2018/08/14/%D0%BA%D0%B0%D0%BA-%D0%B8%D1%81%D0%BF%D1%80%D0%B0%D0%B2%D0%B8%D1%82%D1%8C-firewall-cmd-command-not-found-%D0%BE%D1%88%D0%B8%D0%B1%D0%BA%D1%83-%D0%B2-rhel-centos-7/)

- Ansible:

  - sample Tomcat .web application -> [tomcat](https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/)

  - dynamic inventory - boto3 -> [devopscuve](https://devopscube.com/setup-ansible-aws-dynamic-inventory/)  

  - vars -> [stackoverflow](https://stackoverflow.com/questions/44734179/specifying-ssh-key-in-ansible-playbook-file)

  - dynamic inventory -> [ansible](https://docs.ansible.com/ansible/2.4/intro_dynamic_inventory.html#example-aws-ec2-external-inventory-script)