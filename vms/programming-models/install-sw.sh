#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y git
sudo apt-get install -y make
sudo apt-get install -y openjdk-7-jre-headless 
sudo apt-get install -y scala
sudo apt-get install -y python-matplotlib
sudo apt-get install -y vim nano emacs  # yes, even emacs

sudo ln -s /usr/lib/jvm/java-7-openjdk-amd64/ /usr/lib/jvm/default-java

readonly BASEDIR=~vagrant
readonly BASHRC=${BASEDIR}/.bashrc
readonly USER=vagrant
readonly GROUP=vagrant

# get anaconda
echo "Miniconda install"
if [ ! -d /miniconda ]
then
    sudo apt-get install -y bzip2
    wget -q --tries=1 --timeout=15 https://repo.continuum.io/miniconda/Miniconda3-4.1.11-Linux-x86_64.sh -O miniconda.sh 
    chmod u+x miniconda.sh && ./miniconda.sh -b -p /miniconda && rm miniconda.sh
    chown -R "${USER}.${GROUP}" /miniconda
    /miniconda/bin/conda update -y conda
    echo 'export PATH="/miniconda/bin:${PATH}"' >> "${BASHRC}"
fi
export PATH="/miniconda/bin:${PATH}"

# Numpy
echo "Numpy, matplotlib"
/miniconda/bin/conda install -y numpy
/miniconda/bin/conda install -y matplotlib

# Jupyter
echo "Jupyter install"
/miniconda/bin/conda install -y jupyter

# Dask
echo "Dask install"
/miniconda/bin/conda install -y dask -c conda-forge
/miniconda/bin/conda install -y graphviz
/miniconda/bin/pip install dask[complete]
/miniconda/bin/pip install graphviz

readonly APACHE_MIRROR=mirror.csclub.uwaterloo.ca/apache/

# Spark
echo "Spark install"
cd "${BASEDIR}"
readonly SPARK_VERSION=1.6.2   # Toree doesn't yet support 2.0.0
readonly SPARK_TAR_GZ=spark-${SPARK_VERSION}-bin-hadoop2.6.tgz   
readonly SPARK_DIR=$( basename ${SPARK_TAR_GZ} .tgz )
if [ ! -d "${SPARK_DIR}" ]
then
  wget -q --tries=1 --timeout=15 http://${APACHE_MIRROR}/spark/spark-${SPARK_VERSION}/${SPARK_TAR_GZ} -O ${SPARK_TAR_GZ}
  tar xzf ${SPARK_TAR_GZ} 2> /dev/null
  chown -R "${USER}.${GROUP}" "${SPARK_DIR}"
  rm ${SPARK_TAR_GZ}
  export SPARK_HOME=${BASEDIR}/${SPARK_DIR}" >> "${BASHRC}
  echo "export SPARK_HOME=${BASEDIR}/${SPARK_DIR}" >> "${BASHRC}"
  py4jzip=$( find "${BASEDIR}/${SPARK_DIR}/python" -name "py4j*src.zip" )
  echo "export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python:${py4jzip}" >> "${BASHRC}"
  cp ${SPARK_HOME}/conf/log4j.properties.template ${SPARK_HOME}/conf/log4j.properties
  sed -i -e 's/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/' ${SPARK_HOME}/conf/log4j.properties
fi
export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python
py4jzip=$( find "${BASEDIR}/${SPARK_DIR}/python" -name "py4j*src.zip" )
export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python:${py4jzip}
echo "export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python" >> ~/.bashrc
echo "export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python:${py4jzip}" >> ~/.bashrc

/miniconda/bin/pip install findspark
/miniconda/bin/pip install toree
jupyter toree install --spark_home=${SPARK_HOME} --interpreters=Scala,PySpark

# install graphframes
cd "${SPARK_HOME}"
./bin/spark-shell --packages graphframes:graphframes:0.2.0-spark1.6-s_2.10 <<EOF
EOF
rm "derby.log"
cd ${BASEDIR}

# Tensorflow
echo "Tensorflow install"
/miniconda/bin/conda install -y -c https://conda.anaconda.org/jjhelmus tensorflow

# Shell in a box; gets g++, needed for Chapel
echo "Shell in a box install"
sudo apt-get install -y libssl-dev libpam0g-dev zlib1g-dev dh-autoreconf
cd "${BASEDIR}"
git clone https://github.com/shellinabox/shellinabox.git && cd shellinabox && autoreconf -i && ./configure && make && make install && cd .. 

# Chapel
echo "Chapel install"
# turn off memory randomization for GASNET
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
readonly CHAPEL_VERSION=1.12.0
readonly CHAPEL_TAR_GZ=chapel-${CHAPEL_VERSION}.tar.gz
readonly CHAPEL_DIR=$( basename ${CHAPEL_TAR_GZ} .tar.gz )
if [ ! -d "$CHAPEL_DIR" ]
then
    cd "${BASEDIR}"
    wget -q --tries=1 --timeout=15 https://github.com/chapel-lang/chapel/releases/download/${CHAPEL_VERSION}/${CHAPEL_TAR_GZ} -O ${CHAPEL_TAR_GZ}
    tar xzf ${CHAPEL_TAR_GZ} 2> /dev/null
    chown -R "${USER}.${GROUP}" "${CHAPEL_DIR}" "${CHAPEL_TAR_GZ}"
    # make sure all chapel python utils are executed with python2 rather than anaconda python3
    find "${CHAPEL_DIR}" -type f  -exec grep "/usr/bin/env python" {} \; -exec sed -i -e 's/env python$/env python2/' {} \;
    rm ${CHAPEL_TAR_GZ}
    cd "${BASEDIR}/${CHAPEL_DIR}" && source util/quickstart/setchplenv.bash && make
    cd "${BASEDIR}/${CHAPEL_DIR}/third-party/gasnet" && make
    export CHPL_COMM=gasnet
    export GASNET_SPAWNFN=L
    cd "${BASEDIR}/${CHAPEL_DIR}" && make
    cd "${BASEDIR}"
    chown -R "${USER}.${GROUP}" "${CHAPEL_DIR}"
    echo "cd ${CHAPEL_DIR} && source util/quickstart/setchplenv.bash && cd ${BASEDIR}" >> "${BASHRC}"
    echo "export CHPL_COMM=gasnet" >> "${BASHRC}"
    echo "export GASNET_SPAWNFN=L" >> "${BASHRC}"
fi

# Examples
cd ${BASEDIR}
git clone https://github.com/ljdursi/EuroMPI2016.git
chown -R ${USER}.${GROUP} EuroMPI2016
for dir in examples 
do
   cp -r EuroMPI2016/${dir} ${BASEDIR}
   chown -R ${USER}.${GROUP} ${BASEDIR}/${dir}
done

sudo mv ${BASEDIR}/EuroMPI2016/vms/programming-models/shellinabox /etc/init.d
sudo mv ${BASEDIR}/EuroMPI2016/vms/programming-models/jupyter /etc/init.d
chmod 755 /etc/init.d/{jupyter,shellinabox}
sudo update-rc.d shellinabox  defaults
sudo update-rc.d jupyter  defaults

rm -rf EuroMPI2016
chown -R ${USER}.${GROUP} ${BASEDIR}

#
# Start up services: 
#   - shellinabox for browser-based ssh access
#   - Jupyter notebook
#

sudo /etc/init.d/shellinabox start
sudo /etc/init.d/jupyter start
