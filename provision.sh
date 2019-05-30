#!/bin/bash

VAGRANT_HOST_DIR=/mnt/host_machine
JENKINS_URL=http://localhost:8080

########################
# Quality of life tools - ensured
########################
sudo apt-get -y install vim screen htop > /dev/null 2>&1
sudo apt-get -y install gcc g++ make > /dev/null 2>&1

########################
# Jenkins & Java
########################
echo "Installing Jenkins and Java"
wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update > /dev/null 2>&1
sudo apt-get -y install default-jdk jenkins > /dev/null 2>&1
echo "Installing Jenkins default user and config"
sudo cp ${VAGRANT_HOST_DIR}/JenkinsConfig/config.xml /var/lib/jenkins/
sudo mkdir -p /var/lib/jenkins/users/admin
sudo cp ${VAGRANT_HOST_DIR}/JenkinsConfig/users/admin/config.xml /var/lib/jenkins/users/admin/
sudo chown -R jenkins:jenkins /var/lib/jenkins/users/

echo "Restarting Jenkins"
sudo service jenkins restart

echo "Waiting for Jenkins to come back up"
RETRY_LIMIT=10
for i in $(seq 1 $RETRY_LIMIT); do
  sleep 2
  response=$(curl -Is $JENKINS_URL/jnlpJars/jenkins-cli.jar | head -n 1)
  echo "$i $response"
  if [[ $response = *"200"* ]]; then
    echo "Jenkins restarted"
    break
  fi
done

echo "Updating Jenkins update centre data"
XMLDOC=$(curl -sL https://updates.jenkins-ci.org/update-center.json)

if [[ $XMLDOC == *"A problem occurred while processing the request"* ]]; then
  # document error!
  echo "Skipping update center data"
else
  echo $XMLDOC | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- $JENKINS_URL/updateCenter/byId/default/postBack
fi

curl -so jenkins-cli.jar $JENKINS_URL/jnlpJars/jenkins-cli.jar

for p in $(cat ${VAGRANT_HOST_DIR}/plugins.txt); do
  echo "Installing Jenkins plugin $p"
  java -jar jenkins-cli.jar -auth admin:admin -s ${JENKINS_URL}/ install-plugin $p
done

echo "Updating other Jenkins plugins"
UPDATE_LIST=$( java -jar jenkins-cli.jar -auth admin:admin -s ${JENKINS_URL}/ list-plugins | grep -e ')$' | awk '{ print $1 }' ); 
if [ ! -z "${UPDATE_LIST}" ]; then 
    echo Updating Jenkins Plugins: ${UPDATE_LIST}; 
    java -jar jenkins-cli.jar -auth admin:admin -s ${JENKINS_URL}/ install-plugin ${UPDATE_LIST};
    java -jar jenkins-cli.jar -auth admin:admin -s ${JENKINS_URL}/ safe-restart;
fi

sudo usermod -a -G jenkins vagrant

########################
# Node & npm
########################
echo "Installing Node & npm"
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get -y install nodejs > /dev/null 2>&1
sudo apt-get -y install npm > /dev/null 2>&1

########################
# Docker
########################
echo "Installing Docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update > /dev/null 2>&1
sudo apt-get -y install docker-ce > /dev/null 2>&1
sudo systemctl enable docker
sudo usermod -aG docker ${USER}
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

########################
# nginx
########################
echo "Installing nginx"
sudo apt-get -y install nginx > /dev/null 2>&1
sudo service nginx start

########################
# Configuring nginx
########################
echo "Configuring nginx"
cd /etc/nginx/sites-available
sudo rm default ../sites-enabled/default
sudo cp ${VAGRANT_HOST_DIR}/VirtualHost/jenkins /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/

########################
# Update all the things
########################
sudo apt-get -y update && sudo apt-get -y upgrade

########################
# Adding title to MOTD
########################
sudo apt-get install update-motd > /dev/null 2>&1
sudo cat ${VAGRANT_HOST_DIR}/motd.sh > /etc/update-motd.d/01-header
sudo chmod 755 /etc/update-motd.d/01-header
sudo /usr/sbin/update-motd

########################
# setting hostname
########################
echo "Setting Hostname"
echo "jenkins" > /etc/hostname
echo "127.0.0.1  jenkins" >> /etc/hosts
echo "Success"
echo "Rebooting"
#sudo reboot