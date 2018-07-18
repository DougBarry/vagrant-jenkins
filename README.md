# Vagrant Jenkins build [![Build Status](https://travis-ci.org/edinc/vagrant-jenkins.svg?branch=master)](https://travis-ci.org/edinc/vagrant-jenkins)

Run latest Jenkins instance on Ubuntu 16.04 LTS using vagrant.

## Prerequisites
* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)

vagrant reload plugin
```
vagrant plugin install vagrant-reload
```

## Installation
Add any Jenkins plugins you require to plugins.txt

Build the vagrant box
```
vagrant up
```

To access the Jenkins server

```
http://localhost:8080
```

or, add the following line to the hosts file

```
127.0.0.1   jenkins.local
```

and then run the server with

```
http://jenkins.local:8080
```

## First time accessing Jenkins
Since version 2.0 Jenkins has a security setup wizard when first running it after the installation.

SSH into the machine with

```
vagrant ssh
```

Locate the security password

```
cat /var/lib/jenkins/secrets/initialAdminPassword
```

and copy it into the password field on the Jenkins server.
