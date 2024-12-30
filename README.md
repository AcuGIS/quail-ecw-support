# Quail Additional Formats

This repository contains installers for additional format support.

## ECW Support

```bash
git clone https://github.com/AcuGIS/quail-formats.git
cd quail-formats
chmod +x ecw-support.sh
./ecw-support.sh
rm -rf quail-formats

```


## Oracle Support

```bash
git clone https://github.com/AcuGIS/quail-formats.git
cd quail-formats
chmod +x ecw-oracle-support.sh
./ecw-oracle-support.sh
rm -rf quail-formats

```


## Build from source
If you want to build a newer version of GDAL, or link agains different Oracle Client version, you can run the build script. It will compile and install current Ubuntu 24 GDAL version. All .deb files will be stored in /root.
```bash
git clone https://github.com/AcuGIS/quail-formats.git
cd quail-formats
chmod +x gdal_ecw_build_ubuntu24.sh
./gdal_ecw_build_ubuntu24.sh
rm -rf quail-formats

```
