#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y git
sudo apt-get install -y make
sudo apt-get install -y openjdk-8-jre-headless 
sudo apt-get install -y scala
sudo apt-get install -y vim nano emacs  # yes, even emacs

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
/miniconda/bin/pip install dask[complete]

# Hadoop
echo "Hodoop install"
APACHE_MIRROR=mirror.csclub.uwaterloo.ca/apache/
HADOOP_VERSION=2.6.4
if [ ! -d hadoop-${HADOOP_VERSION} ]
then
  HADOOP_TAR_GZ=hadoop-$HADOOP_VERSION.tar.gz
  wget -q --tries=1 --timeout=15 http://${APACHE_MIRROR}/hadoop/common/hadoop-${HADOOP_VERSION}/$HADOOP_TAR_GZ
  tar xzf $HADOOP_TAR_GZ
  chown -R "${USER}.${GROUP}" "hadoop-${HADOOP_VERSION}"
  rm "$HADOOP_TAR_GZ"
fi

# Spark
echo "Spark install"
cd "${BASEDIR}"
SPARK_VERSION=1.6.2   # Toree doesn't yet support 2.0.0
SPARK_TAR_GZ=spark-${SPARK_VERSION}-bin-hadoop2.6.tgz   
SPARK_DIR=$( basename ${SPARK_TAR_GZ} .tgz )
if [ ! -d "${SPARK_DIR}" ]
then
  wget -q --tries=1 --timeout=15 http://${APACHE_MIRROR}/spark/spark-${SPARK_VERSION}/${SPARK_TAR_GZ} -O ${SPARK_TAR_GZ}
  tar xzf ${SPARK_TAR_GZ} 2> /dev/null
  chown -R "${USER}.${GROUP}" "${SPARK_DIR}"
  rm ${SPARK_TAR_GZ}
  echo "export SPARK_HOME=${BASEDIR}/${SPARK_DIR}" >> "${BASHRC}"
  py4jzip=$( find "${BASEDIR}/${SPARK_DIR}/python" -name "py4j*src.zip" )
  echo "export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python:${py4jzip}" >> "${BASHRC}"
fi
export SPARK_HOME=${BASEDIR}/${SPARK_DIR}
export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python
py4jzip=$( find "${BASEDIR}/${SPARK_DIR}/python" -name "py4j*src.zip" )
export PYTHONPATH=${PYTHONPATH}:${BASEDIR}/${SPARK_DIR}/python:${py4jzip}

/miniconda/bin/pip install findspark
/miniconda/bin/pip install toree
jupyter toree install --spark_home=${SPARK_HOME}

# install graphframes
cd "${BASEDIR}"
"$SPARK_HOME/bin/spark-shell" --packages graphframes:graphframes:0.2.0-spark2.0-s_2.11 <<EOF
EOF
rm "${BASEDIR}/derby.log"

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
CHAPEL_VERSION=1.12.0
CHAPEL_TAR_GZ=chapel-${CHAPEL_VERSION}.tar.gz
CHAPEL_DIR=$( basename ${CHAPEL_TAR_GZ} .tar.gz )
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
git clone https://github.com/ljdursi/Spark-Chapel-TF-UMich-2016.git
chown -R ${USER}.${GROUP} Spark-Chapel-TF-UMich-2016
for dir in bin examples hadoop-config
do
   cp -r Spark-Chapel-TF-UMich-2016/${dir} ${BASEDIR}
   chown -R ${USER}.${GROUP} ${BASEDIR}/${dir}
done
sudo cp ${BASEDIR}/Spark-Chapel-TF-UMich-2016/vm/shellinabox /etc/init.d
sudo cp ${BASEDIR}/Spark-Chapel-TF-UMich-2016/vm/jupyter /etc/init.d
chmod 755 /etc/init.d/{jupyter,shellinabox}
sudo update-rc.d shellinabox  defaults
sudo update-rc.d jupyter  defaults
rm -rf Spark-Chapel-TF-UMich-2016
cp -r ${BASEDIR}/examples ${BASEDIR}/examples
chown -R ${USER}.${GROUP} ${BASEDIR}/examples

echo "source ~/bin/setup.sh" >> ${BASHRC}

for file in ${BASEDIR}/hadoop-config/etc/hadoop/* ; do mv $file ${BASEDIR}/hadoop-${HADOOP_VERSION}/etc/hadoop/; done
rm -rf hadoop-config
export HADOOP_CONF_DIR="${BASEDIR}/hadoop-${HADOOP_VERSION}"
echo "export HADOOP_CONF_DIR=\"${BASEDIR}/hadoop-${HADOOP_VERSION}\"" >> ~/.bashrc

#
# Start up services: 
#   - shellinabox for browser-based ssh access
#   - Jupyter notebook
#

sudo /etc/init.d/shellinabox start
sudo /etc/init.d/jupyter start
