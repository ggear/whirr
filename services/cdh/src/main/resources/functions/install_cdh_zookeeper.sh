#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -x
function register_cloudera_repo() {
  CDH_MAJOR_VERSION=$(echo $REPO | sed -e 's/cdh\([0-9]\).*/\1/')
  CDH_VERSION=$(echo $REPO | sed -e 's/cdh\([0-9][0-9]*\)/\1/')
  if which dpkg &> /dev/null; then
	retry_apt-get -y install lsb-release
	OS_CODENAME=$(lsb_release -sc)
	OS_DISTID=$(lsb_release -si | tr '[A-Z]' '[a-z]')
    if [ $CDH_MAJOR_VERSION -gt 3 ]; then
      cat > /etc/apt/sources.list.d/cloudera-$REPO.list <<EOF
deb http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/$OS_DISTID/$OS_CODENAME/amd64/cdh $OS_CODENAME-$REPO contrib
deb-src http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/$OS_DISTID/$OS_CODENAME/amd64/cdh $OS_CODENAME-$REPO contrib
EOF
      curl -s http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/$OS_DISTID/$OS_CODENAME/amd64/cdh/archive.key | apt-key add -
    else
      cat > /etc/apt/sources.list.d/cloudera-$REPO.list <<EOF
deb http://$REPO_HOST/debian $OS_CODENAME-$REPO contrib
deb-src http://$REPO_HOST/debian $OS_CODENAME-$REPO contrib
EOF
      curl -s http://$REPO_HOST/debian/archive.key | apt-key add -
    fi
    retry_apt_get -y update
  elif which rpm &> /dev/null; then
    if [ $CDH_MAJOR_VERSION -gt 3 ]; then
      cat > /etc/yum.repos.d/cloudera-$REPO.repo <<EOF
[cloudera-$REPO]
name=Cloudera's Distribution for Hadoop, Version $CDH_VERSION
baseurl=http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/redhat/\$releasever/\$basearch/cdh/$CDH_VERSION/
gpgkey=http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/redhat/\$releasever/\$basearch/cdh/RPM-GPG-KEY-cloudera
gpgcheck=1
EOF
      rpm --import http://$REPO_HOST/cdh$CDH_MAJOR_VERSION/redhat/\$releasever/\$basearch/cdh/RPM-GPG-KEY-cloudera
    else
      if [ $(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release)) -gt 5 ]; then
        OS_VERSION_ARCH="\$releasever/\$basearch/";
      fi	
      cat > /etc/yum.repos.d/cloudera-$REPO.repo <<EOF
[cloudera-$REPO]
name=Cloudera's Distribution for Hadoop, Version $CDH_VERSION
mirrorlist=http://$REPO_HOST/redhat/$OS_VERSION_ARCH/cdh/$CDH_VERSION/mirrors
gpgkey=http://$REPO_HOST/redhat/$OS_VERSION_ARCH/cdh/RPM-GPG-KEY-cloudera
gpgcheck=1
EOF
      rpm --import http://$REPO_HOST/redhat/$OS_VERSION_ARCH/cdh/RPM-GPG-KEY-cloudera
    fi
    retry_yum update -y retry_yum
  fi
}

function install_cdh_zookeeper() {
  local OPTIND
  local OPTARG
  
  case $CLOUD_PROVIDER in
    ec2 | aws-ec2 )
      # Alias /mnt as /data
      if [ ! -e /data ]; then ln -s /mnt /data; fi
      ;;
    *)
      ;;
  esac
  
  REPO=${REPO:-cdh4}
  REPO_HOST=${REPO_HOST:-archive.cloudera.com}
  ZOOKEEPER_HOME=/usr/lib/zookeeper
  ZK_CONF_DIR=/etc/zookeeper
  ZK_LOG_DIR=/var/log/zookeeper
  ZK_DATA_DIR=$ZK_LOG_DIR/txlog

  CDH_MAJOR_VERSION=$(echo $REPO | sed -e 's/cdh\([0-9]\).*/\1/')
  ZOOKEEPER_PACKAGE=hadoop-zookeeper
  if [ $CDH_MAJOR_VERSION = "4" ]; then
    ZOOKEEPER_PACKAGE=zookeeper
    ZK_CONF_DIR=/etc/zookeeper/conf
  fi

  register_cloudera_repo
  
  if which dpkg &> /dev/null; then
    retry_apt_get update
    retry_apt_get -y install $ZOOKEEPER_PACKAGE
  elif which rpm &> /dev/null; then
    retry_yum install -y $ZOOKEEPER_PACKAGE
  fi
  
  echo "export ZOOKEEPER_HOME=$ZOOKEEPER_HOME" >> /etc/profile
  echo 'export PATH=$ZOOKEEPER_HOME/bin:$PATH' >> /etc/profile
  
  rm -rf $ZK_LOG_DIR
  mkdir -p /data/zookeeper/logs
  ln -s /data/zookeeper/logs $ZK_LOG_DIR
  mkdir -p $ZK_LOG_DIR/txlog
  chown -R zookeeper:zookeeper /data/zookeeper/logs
  chown -R zookeeper:zookeeper $ZK_LOG_DIR
  
  sed -i -e "s|zookeeper.root.logger=.*|zookeeper.root.logger=INFO, ROLLINGFILE|" \
         -e "s|zookeeper.log.dir=.*|zookeeper.log.dir=$ZK_LOG_DIR|" \
         -e "s|zookeeper.tracelog.dir=.*|zookeeper.tracelog.dir=$ZK_LOG_DIR|" \
      $ZK_CONF_DIR/log4j.properties
}
