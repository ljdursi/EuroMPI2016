#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y git
sudo apt-get install -y make
sudo apt-get install -y openjdk-7-jre-headless 
sudo apt-get install -y scala  sbt # takes care of akka
sudo apt-get install -y vim nano emacs  # yes, even emacs
sudo apt-get install -y g++ gcc
sudo apt-get install -y libssl-dev libpam0g-dev zlib1g-dev dh-autoreconf
sudo apt-get install -y openmpi-bin openmpi-doc libopenmpi-dev
sudo apt-get install -y libpcap libpcap-dev

readonly BASEDIR=~vagrant
readonly BASHRC=${BASEDIR}/.bashrc
readonly USER=vagrant
readonly GROUP=vagrant

export MPI_CC=$( which mpicc )
export MPI_CXX=$( which mpicxx )
echo "export MPI_CC=${MPI_CC}" >> ~/.bashrc
echo "export MPI_CXX=${MPI_CXX}" >> ~/.bashrc

function getas {
    local URL=$1
    local output=$2
    wget -q --tries=1 --timeout=15 ${URL} -O ${output}
}

# Shell in a box; gets g++, needed for Chapel
echo "Shell in a box install"
cd "${BASEDIR}"
git clone https://github.com/shellinabox/shellinabox.git\
    && cd shellinabox\
    && autoreconf -i\
    && ./configure\
    && make\
    && make install\
    && cd .. 

# Akka dist - mainly for the examples
cd "${BASEDIR}"
git clone git://github.com/akka/akka.git

# GASNET
echo "GASNET Install"
GASNET_VERSION=1.26.4
GASNET_TGZ=GASNet-${GASNET_VERSION}.tar.gz
if [[ ! -d ${BASEDIR}/GASNet-${GASNET_VERSION} ]]
then
    cd "${BASEDIR}"
    getas https://gasnet.lbl.gov/${GASNET_TGZ} ${GASNET_TGZ}
    tar -xzvf ${GASNET_TGZ}
    cd GASNet-${GASNET_VERSION}
    ./configure --prefix=/opt/gasnet
    make all
    make install
    echo "export GASNET_SPAWNFN=L" >> "${BASHRC}"
    rm -rf ${GASNET_TGZ}
fi

# DPDK
DPDK_VERSION=16.07
DPDK_DIR=dpdk-${DPDK_VERSION}
DPDX_TARXZ=dpdk-${DPDK_VERSION}.tar.xz
DPDX_URL=http://fast.dpdk.org/rel/${DPDX_TARXZ}
cd ${BASEDIR}
echo "DPDK Install"
if [[ ! -d ${DPDK_DIR} ]] 
then
    getas ${DPDX_URL} ${DPDX_TARXZ} 
    tar -xjvf ${DPDX_TARXZ}
    rm ${DPDX_TARXZ}
    cd ${DPDK_DIR}
    make config T=x86_64-native-linuxapp-gcc
    sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config
    make
    mkdir -p /mnt/huge
    mount -t hugetlbfs nodev /mnt/huge
    echo 64 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
    build/app/testpmd -c7 -n3 --vdev=eth_pcap0,iface=eth0 --vdev=eth_pcap1,iface=eth1 --\
                      -i --nb-cores=2 --nb-ports=2 --total-num-mbufs=2048
fi

# LIBFABRIC 
LIBFABRIC_VERSION="1.3.0"
LIBFABRIC_TARGZ=libfabric-${LIBFABRIC_VERSION}.tar.gz
LIBFABRIC_URL=https://github.com/ofiwg/libfabric/releases/download/v${LIBFABRIC_VERSION}/${LIBFABRIC_TARGZ}
LIBFABRIC_DIR=libfabric-${LIBFABRIC_VERSION}
if [[ ! -d ${LIBFABRIC_DIR} ]]
then
    getas ${LIBFABRIC_URL} ${LIBFABRIC_TARGZ} 
    tar -xzvf ${LIBFABRIC_TARGZ} 
    rm ${LIBFABRIC_TARGZ} 
    ./configure --prefix=/opt/libfabric
    make
    make install
fi

# UCX
cd ${BASEDIR}
echo "UCX Install"
if [[ ! -d openucx-ucx ]] 
then
    getas https://github.com/uccs/ucx/tarball/master ucx.tgz
    tar -xzvf ucx.tgz
    rm ucx.tgz
    mv openucx-ucx-* openucx-ucx
    cd openucx-ucx
    ./autogen.sh
    ./contrib/configure-release --prefix=$PWD/install --with-mpi
    make -j8 install
fi

cd ${BASEDIR}
git clone https://github.com/ljdursi/EuroMPI2016.git
sudo mv ${BASEDIR}/EuroMPI2016/vms/programming-models/shellinabox /etc/init.d
chmod 755 /etc/init.d/shellinabox
sudo update-rc.d shellinabox  defaults
rm -rf EuroMPI2016

chown -R ${USER}.${GROUP} ${BASEDIR}

#
# Start up services: 
#   - shellinabox for browser-based ssh access

sudo /etc/init.d/shellinabox start
