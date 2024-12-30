#!/bin/bash -e

# https://help.ubuntu.com/community/UpdatingADeb
# https://gdal.org/en/stable/development/building_from_source.html
# https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html

NP=$(grep -c 'model' /proc/cpuinfo)

# install libecw
function build_libecwj2(){
	wget -P/tmp https://github.com/sasgis/libecwj2/archive/refs/heads/master.zip
	unzip /tmp/master.zip
	rm -rf /tmp/master.zip

	pushd libecwj2-master
		chmod +x ./configure
		./configure
		make -j${NP}
		#make install
		checkinstall -Dy --install=yes --fstrans=no --pkgname="libecwj2" --pkgversion="3.3" --backup=no --nodoc
		mv libecwj2_3.3-1_amd64.deb /root/libecwj2_3.3-1_amd64.deb
	popd
	rm -rf libecwj2-master
}

function build_kealib(){
	
	apt-get -y install libhdf5-dev libhdf5-103-1t64 libhdf5-cpp-103-1t64 cmake
	
	wget -P/tmp https://github.com/ubarsc/kealib/releases/download/kealib-1.6.0/kealib-1.6.0.zip
	unzip /tmp/kealib-1.6.0.zip
	
	pushd kealib-1.6.0/
		mkdir build
		pushd build
			cmake ..
			
			#change libname to serial in CMakeLists.txt
			# set(HDF5_LIBRARIES "-L${HDF5_LIB_PATH} -lhdf5_serial -lhdf5_serial_hl -lhdf5_cpp")
			make -j${NP}
			#make install
			checkinstall -Dy --install=yes --fstrans=no --pkgname="kealib" --pkgversion="1.6.0" --backup=no --nodoc
			mv kealib_1.6.0-1_amd64.deb /root
		popd
	popd
	rm -rf kealib-1.6.0
}

function install_szip(){
	# libaec-dev replaces szip-2.1
	apt-get -y install libaec-dev
}

function build_libgta(){
	apt-get install -y liblzma-dev libbz2-dev
	
	wget -P/tmp https://marlam.de/gta/releases/libgta-1.2.1.tar.xz
	tar -xf /tmp/libgta-1.2.1.tar.xz
	rm -rf /tmp/libgta-1.2.1.tar.xz

	pushd libgta-1.2.1/	
		./configure --prefix=/usr
		make -j${NP}
		#make install
		checkinstall -Dy --install=yes --fstrans=no --pkgname="libgta" --pkgversion="1.2.1" --backup=no --nodoc
		mv libgta_1.2.1-1_amd64.deb /root
	popd
	rm -rf libgta-1.2.1
}

function install_fyba(){
	apt-get -y install libfyba-dev
}

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

function build_gdal(){
	pkg="gdal"
	#apt-add-repository -y universe
	
	# enable sources repository
	sed -i.save 's/Types: deb/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
	apt-get -y update
	apt-get -y build-dep ${pkg}
	apt-get -y install build-essential fakeroot devscripts libltdl-dev \
		swig4.1 python3 bison libcrypto++-dev default-jdk librasterlite2-dev \
		libpodofo-dev libopenexr-dev

	mkdir src
	pushd src
		apt-get -y source ${pkg}
		pushd gdal-3.*
			
			sed -i.save '
s|\-\-with\-pg|--with-pg --with-ecw=yes|
s|\-DGDAL_USE_ECW=OFF|-DGDAL_USE_ECW=ON|' debian/rules
	
			if [ -d /opt/oracle/instantclient_23_6/ ]; then
				source /etc/profile.d/oci.sh
				sed -i.save "/\-DGDAL_USE_ECW=ON/i\-DOracle_ROOT=${ORACLE_HOME} -DGDAL_USE_ORACLE=ON \\\\" debian/rules
			fi

			cat >> debian/rules <<CAT_EOF
override_dh_shlibdeps:
	dh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info
CAT_EOF

			DEB_BUILD_OPTIONS="parallel=${NP}" debuild -us -uc -i -I
			debi
		popd
		
		mv *.deb /root/
		rm -rf *.ddeb
		rm -rf gdal-3.*
	popd


	# hold package to avoid overwriteing on updates
	for p in gdal-bin gdal-data libgdal34t64 libgdal-dev python3-gdal; do
		echo "${p} hold" | dpkg --set-selections
	done
	# echo "${pkg} install" | dpkg --set-selections
	
	# disable sources
	sed -i.save 's/Types: deb deb-src/Types: deb/' /etc/apt/sources.list.d/ubuntu.sources
	apt-get -y clean all
}

export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y install checkinstall unzip

build_libecwj2
build_kealib
install_szip
build_libgta
install_fyba
install_oci
build_gdal
