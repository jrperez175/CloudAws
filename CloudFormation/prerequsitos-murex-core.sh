#!/bin/bash
set -x
#paquetes prerrequisitos de murex, efs y otros componentes
yum install libstdc++ libgcc glibc zlib libXt libXext libXtst libaio openssl rng-tools nfs-utils tmux bash-completion xorg-x11-server-Xorg xorg-x11-xauth xorg-x11-apps gcc binutils compat-libstdc++ elfutils-libelf gcc gcc-c++ libaio libaio-devel libgcc libstdc++-devel sysstat unixODBC unixODBC-devel telnet net-tool -y

#creacion de usuarios
groupadd -g 507 dba
groupadd -g 70000001 grpucd
groupadd -g 500 murex
useradd  -u 500 murex -g murex -c "Administrador Aplicacion MUREX" -G grpucd
useradd  -u 519 oracle -g dba -c "Oracle - DBA " -d /opt/oracle -m
echo "kernel.pid_max=999999" >> /etc/sysctl.conf
sysctl	-p

###en on premise el nofiel se encuentra en 8192
echo "############ PARAMETRIZACION APP MUREX##########" >> /etc/security/limits.conf
echo -e "murex\t\tsoft\tnofile\t\t2048" >> /etc/security/limits.conf
echo -e "murex\t\thard\tnofile\t\t2048" >> /etc/security/limits.conf
echo -e "murex\t\tsoft\tstack\t\t1024" >> /etc/security/limits.conf
echo -e "murex\t\thard\tstack\t\t1024" >> /etc/security/limits.conf
echo -e "murex\t\thard\tnproc\t\t790527" >> /etc/security/limits.conf
echo -e "murex\t\tsoft\tnproc\t\t790527" >> /etc/security/limits.conf
echo -e "murex\t\thard\tcore\t\tunlimited" >> /etc/security/limits.conf
echo -e "murex\t\tsoft\tcore\t\tunlimited" >> /etc/security/limits.conf
echo "############ FIN PARAMETRIZACION APP MUREX##########" >> /etc/security/limits.conf

#se inicia el servicio rngd
systemctl enable rngd
systemctl start rngd

#desactivar
setenforce 0


# instalacion java /usr/local/java/
mkdir /tmp/assets
aws s3 cp s3://${bucketfile}/jdk1.7.0_151.tar /tmp/assets
mkdir  /usr/local/java
cp -v /tmp/assets/jdk1.7.0_151.tar /usr/local/java/
tar xvf /usr/local/java/jdk1.7.0_151.tar -C /usr/local/java/
alternatives --install /usr/local/java/jdk1.7.0_151/java java /usr/local/java/jdk1.7.0_151/bin/java 1
echo "export PATH=$PATH:/usr/local/java/jdk1.7.0_151/bin:/usr/local/java/jdk1.7.0_151/jre/bin" >> /etc/profile

# instalacion nmon
aws s3 cp s3://${bucketfile}/nmon-16g-3.el7.x86_64.rpm /tmp/assets
rpm -ihv /tmp/assets/nmon-16g-3.el7.x86_64.rpm

#instalacion de oracle
su - oracle -c "mkdir /tmp/installoracle/"
su - oracle -c "mkdir /tmp/installoracle/parche"
su - oracle -c "aws s3 cp s3://${bucketfile}/linux.x64_11gR2_client.zip  /tmp/installoracle/ "
su - oracle -c "aws s3 cp s3://${bucketfile}/p13390677_112040_Linux-x86-64_4of7.zip  /tmp/installoracle/"
su - oracle -c "unzip /tmp/installoracle/linux.x64_11gR2_client.zip -d /tmp/installoracle/"
su - oracle -c "unzip /tmp/installoracle/p13390677_112040_Linux-x86-64_4of7.zip -d /tmp/installoracle/parche"
su - oracle -c "rm -fr /tmp/installoracle/p13390677_112040_Linux-x86-64_4of7.zip"
su - oracle -c "rm -fr /tmp/installoracle/linux.x64_11gR2_client.zip"
touch /etc/oraInst.loc
echo "inventory_loc=/opt/oracle/oraInventory" >> /etc/oraInst.loc
echo  "inst_group=dba" >> /etc/oraInst.loc >> /etc/oraInst.loc
echo export "ORACLE_BASE=/opt/oracle/base" >> /opt/oracle/.bash_profile
echo export "ORACLE_HOME=/opt/oracle/11204_64" >> /opt/oracle/.bash_profile
echo export "LD_LIBRARY_PATH=/opt/oracle/11204_64/lib" >> /opt/oracle/.bash_profile
echo "umask 0022"  >> /opt/oracle/.bash_profile
echo "export PATH=$PATH:/usr/local/java/jdk1.7.0_151/bin:/usr/local/java/jdk1.7.0_151/jre/bin" >> /opt/oracle/.bash_profile
source /opt/oracle/.bash_profile
su - oracle -c "/tmp/installoracle/client/./runInstaller -silent -debug -force FROM_LOCATION=/tmp/installoracle/client/stage/products.xml UNIX_GROUP_NAME=dba ORACLE_HOME=/opt/oracle/11204_64 ORACLE_HOME_NAME="OraClient11g" ORACLE_BASE=/opt/oracle/base oracle.install.client.installType="Administrator" -ignoreSysPrereqs -ignorePrereq ; sleep 80"
su - oracle -c "/tmp/installoracle/parche/client/./runInstaller -silent -debug -force FROM_LOCATION=/tmp/installoracle/parche/client/stage/products.xml UNIX_GROUP_NAME=dba ORACLE_HOME=/opt/oracle/11204_64 ORACLE_HOME_NAME="OraClient11g" ORACLE_BASE=/opt/oracle/base oracle.install.client.installType="Administrator" -ignoreSysPrereqs -ignorePrereq"

#desactivar el selinux permanentemente
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce

shutdown -r +5
