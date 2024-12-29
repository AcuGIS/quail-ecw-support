#!/bin/bash -e

FTP_PASSWORD=''

function install_oci(){
	mkdir /opt/oracle

	for t in basic sdk tools sqlplus; do
		wget -P/tmp https://download.oracle.com/otn_software/linux/instantclient/2360000/instantclient-${t}-linux.x64-23.6.0.24.10.zip
		unzip -aoud /opt/oracle /tmp/instantclient-${t}-linux.x64-23.6.0.24.10.zip
		rm -rf /tmp/instantclient-${t}-linux.x64-23.6.0.24.10.zip
	done
	
	pushd /opt/oracle
	popd
	
	echo /opt/oracle/instantclient_23_6 > /etc/ld.so.conf.d/oracle-instantclient.conf
	ldconfig
	
	ln -s /opt/oracle/instantclient_23_6/sdk/include /opt/oracle/instantclient_23_6/include
	
	cat >/etc/profile.d/oci.sh <<CAT_EOF
export ORACLE_HOME=/opt/oracle/instantclient_23_6
export LD_LIBRARY_PATH=/opt/oracle/instantclient_23_6:\$LD_LIBRARY_PATH
export PATH=\$PATH:/opt/oracle/instantclient_23_6/bin
CAT_EOF

	# fix for libAIO link name
	ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1
}

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y install wget ftp unzip

if [ -z $"{FTP_PASSWORD}" ]; then
	echo "Error: FTP_PASSWORD not set!"; exit 1;
fi

BUILD='ecw'
if [ $1 == '--with-oci' ]; then
	if [ ! -d /opt/oracle/instantclient_23_6 ]; then
		install_oci
	fi
	BUILD='ecw_oci'
fi

mkdir gdal_${BUILD}_3.8.4_ubuntu24
pushd gdal_${BUILD}_3.8.4_ubuntu24
	apt-get -y install ./*.deb
popd

# hold package to avoid overwriteing on updates
for p in gdal-bin gdal-data libgdal34t64 libgdal-dev python3-gdal; do
	echo "${p} hold" | dpkg --set-selections
done