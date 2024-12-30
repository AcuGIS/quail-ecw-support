#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive

apt-get -y update

pushd debs_ubuntu24
	apt-get -y install ./*.deb
	pushd gdal_ecw_3.8.4
		apt-get -y install ./*.deb
	popd
popd

# hold package to avoid overwriteing on updates
for p in gdal-bin gdal-data libgdal34t64 libgdal-dev python3-gdal; do
	echo "${p} hold" | dpkg --set-selections
done
