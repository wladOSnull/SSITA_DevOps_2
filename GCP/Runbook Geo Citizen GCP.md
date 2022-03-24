# Geo Citizen

## GCP general

First steps:

- manually: first VM guide -> [youtube](https://www.youtube.com/watch?v=D-Wf-ZzH1PE)

- create IAM

- create *DevOps* instance with static IP + SSH alias

Terraform-GCP:

- first VMs for Geo Citizen by Terraform -> [youtube](https://www.youtube.com/watch?v=VKBCKhA7G8A)

- backend remote state for Terrafor -> [terraform](https://www.terraform.io/language/settings/backends/gcs)

  - firstly create GCS bucket !
  - in block *backend* add *credentials=/full/path/creds.json* line

- dynamic inventory -> [devopscube](https://devopscube.com/ansible-dymanic-inventry-google-cloud/#:~:text=It%20is%20an%20ansible%20google,group%20instances%20based%20on%20names.)

  - enable GCP dynamic plugin *gcp_compute* in *ansible.cfg*:
  
    ```bash
    ~ sudo nano /etc/ansible/ansible.cfg
    ```

    ```md
    # text to write

    [inventory]
    ...
    enable_plugins = aws_ec2, gcp_compute
    ```

- usage of dynamic GCP inventory -> [ansible](https://docs.ansible.com/ansible/latest/collections/google/cloud/gcp_compute_inventory.html)

## GCP 'dev-ops' instance

To manage GCP compute instances (create, delete, SSH ...) and use GCS bucket we need *main* instance with attached Service Account that contain some Roles (in this case):

  - Compute Instance Admin (beta)
  - Compute Security Admin
  - Storage Admin
  - Compute Public IP Admin

Also this instance must have ingres Firewall with opened ports for:

  - SSH 22
  - AWX 8043

VM **has to have** min 2*CPU + 6-8GB of ROM due to resource-intensive build of AWX front-end - on peak load ~6.1GB of ROM but only 3.6GB of ROM on idle time.

Preset CentOS 7 to build AWX (Docker type):

- update system by *yum*

- installing *docker* -> [docker](https://docs.docker.com/engine/install/centos/)

  - start+enable *docker* service !

  - enable *docker* autocomplete -> [medium](https://ismailyenigul.medium.com/enable-docker-command-line-auto-completion-in-bash-on-centos-ubuntu-5f1ac999a8a6)


  - fixing *dial unix /var/run/docker.sock: connect: permission denied* -> [digitalocean](https://www.digitalocean.com/community/questions/how-to-fix-docker-got-permission-denied-while-trying-to-connect-to-the-docker-daemon-socket)

- install *docker-compose* -> [docker](https://docs.docker.com/compose/install/)

  - enable *docker-compose* autocomplete -> [docker](https://docs.docker.com/compose/completion/)

- install *git*

- install *python3*

- update *pip3* to latest

  ```bash
  ~ sudo pip3 install --upgrade pip3
  ```

- install regular *ansible*

- install *ansible* python module

  ```bash
  ~ pip3 install ansible
  ```

- install build utilities

  ```bash
  ~ sudo yum groupinstall "Development Tools"
  ```

- install *openssl* -> [cloudwafer](https://cloudwafer.com/blog/installing-openssl-on-centos-7/)
- OR install by *INSTALL.md* in *openssl* tarball

  - you may need to install *IPC-Cmd* perl module for *./Configure* command [stackoverflow](https://stackoverflow.com/questions/70464585/error-when-installing-openssl-3-0-1-cant-locate-ipc-cmd-pm-in-inc/70469372)

  - you may need to install *Test-Simple* perl module for *make test* command [github issue](https://github.com/memcached/memcached/issues/580)

Install Ansible AWX -> [github](https://github.com/ansible/awx/blob/devel/tools/docker-compose/README.md) (short explanation):

  - get project by *git*

    ```bash
    # x.y.z - version of AWX on official github repo in: Switch branches or tags - Tags - x.y.z
    ~ git clone -b x.y.z https://github.com/ansible/awx.git
    ```

  - disable *selinux* -> [linuxize](https://linuxize.com/post/how-to-disable-selinux-on-centos-7/)

  - disable *firewalld* !

  - build docker image

    ```bash
    ~ make docker-compose-build
    ```

  - check if docker image was built

    ```bash
    ~ docker images

    # there will be image name like 'quay.io/awx/awx_devel' with big size 1-2GB
    ```

  - build docker containers from image

    ```bash
    ~ make docker-compose
    ```

    - if there is problem with *make: docker-compose* there is solution -> [stackoverflow](https://stackoverflow.com/questions/66002152/ansible-awx-installation-failed-because-of-docker-compose)

  - *OPTIONAL*: all this following tools must be already in tools_awx_1 container< but if you want ot build front-end separatelly you have to have *node >= 16.14.0*, *npm >= 8.x*, *make*, *git*

    ```bash
    # to get repository with npm ...
    ~ curl -fsSL https://rpm.nodesource.com/setup_17.x | sudo bash -

    # to install npm
    ~ sudo yum install npm

    # to install nvm
    ~ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    # reload CLI environment

    # to install latest node
    ~ nvm install node
    ```

  - build front-end

    ```bash
    ~ docker exec tools_awx_1 make clean-ui ui-devel
    ```

- admin user of AWX have to be created by yourself (guide has a command after front-end building), you have to provide during user creation: username and password

  - to generate strong password use *pwgen* -> [linuxconfig](https://linuxconfig.org/how-to-use-a-command-line-random-password-generator-pwgen-on-linux)  

- to get some another credentials generated during installation

  ```bash
  ~ sudo ls -la ./tools/docker-compose/_sources/secrets/
  ```

- try to login in AWX Console

  - visit on web browser https//:public-IP-of-instance:8043

  - enter login+pass that you provided during user generation

## Jenkins

### Installation + configuration

Installing *jenkins* by official guide -> [jenkins](https://www.jenkins.io/doc/book/installing/linux/). Follow the instructions in the section of your OS, Rocky Linux in this case so use *Red Hat / Centos* chapter. 

If there is problem with *deamonize* there is fix -> [unixcloudfusion](https://www.unixcloudfusion.in/2021/09/solved-error-package-jenkins-23031.html)

Short version for whole proccess of OS configuring and Jenkins installation+configuring:

  ```bash
  # general updating of the system
  ~ sudo yum update

  # Java installing for Jenkins
  ~ sudo yum install java-11-openjdk.x86_64
  
  # daemonize installing for Jenkins
  ~ sudo yum install epel-release
  ~ sudo yum update
  ~ sudo yum install daemonize
  
  # getting repo LTS Jenkins
  ~ sudo yum install wget
  ~ sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
  ~ sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

  # Jenkins installing
  ~ sudo yum install jenkins
  ~ sudo systemctl daemon-reload

  # open ports by firewalld
  ~ sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
  ~ sudo firewalld-cmd --reload

  # starting+enabling Jenkins
  ~ sudo systemctl enable jenkins
  ~ sudo systemctl start jenkins
  ~ sudo systemctl status jenkins
  ```

- visit Jenkins start page for next configuring

  - open in web-browser http://public-ip-of-instance:8080

- pass secret code to *Unlock Jenkins*, this code is autogenerated during Jenkins installation

  ```bash
  ~ sudo vi /var/lib/jenkins/secrets/initialAdminPassword
  ```

- choose *Install Suggested Plugin*

- create first *admin* type user

  - use *pwgen* for generating strong password

- enjoy

### Working with projects

Firstly install and setup AWX (Tower is available only) and Terraform plugins for Jenkins.

Official page of Jenkins AWX plugin has enough info about configuring AWX jobs/workflows -> [plugins.jenkins](https://plugins.jenkins.io/ansible-tower/)

Small tutorials/guides for Jenkins-Terraform:

  - default project -> [youtube](https://www.youtube.com/watch?v=5jwYGCAr_pw)
  - parametrized project -> [youtube](https://www.youtube.com/watch?v=vRG_JqTwb94)

Trigger URL for **building** Geo Citizen infrastructure: http://jenkins-ip:8080/job/Terraform%20Geo%20Citizen/build?token=geoinfrastructure&PARAMETER=apply  

Trigger URL for **destroy** Geo Citizen infrastructure: http://jenkins-ip:8080/job/Terraform%20Geo%20Citizen/build?token=geoinfrastructure&PARAMETER=destroy  

Trigger URL for **full** Geo Citizen **workflow**: http://jenkins-ip:8080/job/Workflow%20Geo%20Citizen/build?token=geoworkflow

### GitHub webhooks

For this feature access to Jenkins VM must be available from anywhere (0.0.0.0/0). Of course, this is not secure way, so **Secure webhooks**  chapter has the solutions ...

The main guide for setup webhooks -> [devopsschool](https://www.devopsschool.com/blog/how-to-build-when-a-change-is-pushed-to-github-in-jenkins/)

Another guide for setup wehooks -> [blazemeter](https://www.blazemeter.com/blog/how-to-integrate-your-github-repository-to-your-jenkins-project)

## Scure webhooks for Jenkins 

### Smee.io

This thing implements secure webhook pipeline: GitHub -> Smee.io <- Firewall <- Jenkins

Main guide -> [youtube](https://www.youtube.com/watch?v=ULe7c-2aPYY)

Guide for establish connecion -> [jenkins](https://www.jenkins.io/blog/2019/01/07/webhook-firewalls/)  

```bash
~ smee --url https://smee.io/autogenerated_id --target http://127.0.0.1:8080/github-webhook/
```

### Webhookrelay

The main guide on official site -> [webhookrelay](https://webhookrelay.com/v1/tutorials/github-webhooks-jenkins-vm.html) 
  - use "Option 2" for creating background *relay* server as system service

There si **right** command for creating and enabling *relay* service:

  ```bash
  ~ sudo /usr/local/bin/relay service install --user wlados -c /opt/config/webhookrelay/relay.yaml
  ~ sudo /usr/local/bin/relay service start
  ~ sudo systemctl status relay

  ~ relay input ls
  ```

For generation of shared secrets use *openssl* (already available on *Jenkins* VM):

  ```bash
  ~ openssl rand -base64 16
  ```

## Slack

### Jenkins

Useful guide on official page of Slack plugin for Jenkins -> [plugins.jenkins](https://plugins.jenkins.io/slack/#plugin-content-creating-your-app)

Video guide -> [youtube](https://www.youtube.com/watch?v=EDVZli8GdUM)

### Jira

Guide for establish cpnnection between Slack and Jira -> [hevodata](https://hevodata.com/learn/jira-slack-integration/)

## Appendix

### psycopg2

Python module *psycopg2* or *psycopg2-binary* is difficult to install on GCP CentOS 7 Image by *pip* due to unknown reasons. In that case you case use *yum* way:

  ```bash
  ~ sudo yum install python-devel postgresql-devel rpm-build
  ~ sudo yum install python-psycopg2
  ```

### Dynamic inventory
Installing roles/collections dynamicaly in AWX -> 
  - [reddit](https://www.reddit.com/r/awx/comments/ojfdbo/how_to_useinstall_galaxy_collections/)
  - [ansible](https://docs.ansible.com/ansible/latest/galaxy/user_guide.html#installing-roles-and-collections-from-the-same-requirements-yml-file)


### Jenkins

Default environment variables -> [perforce](https://www.perforce.com/manuals/jenkins/Content/P4Jenkins/variable-expansion.html)

Jenkins variables for *currentBuild* -> [novaordis](https://kb.novaordis.com/index.php/Jenkins_currentBuild#rawBuild)  
E.g. :

  ```bash
  ~ slackSend color: 'good', message: "${currentBuild.currentResult}"
  ```

### Fixes

AWX *remote_tmp* error fixing - [ansible](https://docs.ansible.com/ansible/2.4/intro_configuration.html#remote-tmp)
