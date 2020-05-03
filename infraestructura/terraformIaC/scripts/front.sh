#!/bin/bash
sudo yum update -y
sudo yum install -y git 
# Clonar nuestro repositorio 
sudo git clone -b Feature-FrontBackInfra-ImplementacionDiseñoAWS https://github.com/andres1397/aik-portal /srv/aik-portal

# Crear variable de entorno

 echo "BACKIP="${aws_instance.aik-portal-back.private_ip}"" >> /etc/environment

# Instalar SaltStack
#sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
sudo curl -L https://bootstrap.saltstack.com -o bootstrap_salt.sh
sudo sh bootstrap_salt.sh
#sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
        
#Put custom minion config in place (for enabling masterless mode)
sudo cp -r /srv/aik-portal/Configuration_Managment/minion.d /etc/salt/
echo -e 'grains:\n roles:\n  - frontend' | sudo tee /etc/salt/minion.d/grains.conf

# Realizar un saltstack completo
sudo salt-call state.apply