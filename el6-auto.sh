#!/bin/sh

# Core 4 Alpha auto-deploy script

try() {
	"$@"
	if [ $? -ne 0 ]; then
		echo "Command failure: $@"
		exit 1
	fi
}

BUILD=${BUILD:-4.1.70-1503}
# need to auto-detect this:
try rm -f .listing
MYSQL_MIRROR=ftp://mirror.anl.gov/pub/mysql/Downloads/MySQL-5.5/
try wget --no-remove-listing $MYSQL_MIRROR
MYSQL_BUILD=`cat .listing | awk '{ print $9 }' | grep MySQL-client | grep el6.x86_64.rpm | sort | tail -n 1`
MYSQL_BUILD="${MYSQL_BUILD##MySQL-client-}"
MYSQL_BUILD="${MYSQL_BUILD%%.el6.*}"
EPEL_VER=6-6
echo $MYSQL_BUILD

try wget http://javadl.sun.com/webapps/download/AutoDL?BundleId=59622 -O jre-6u31-linux-x64-rpm.bin
try chmod +x jre-6u31-linux-x64-rpm.bin; try ./jre-6u31-linux-x64-rpm.bin

# set up rrdtool, etc.

try yum -y install xorg-x11-fonts-Type1 ruby libdbi
try wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
try rpm -ivh rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm

try wget http://pkgs.repoforge.org/rrdtool/rrdtool-1.4.7-1.el6.rfx.x86_64.rpm
try wget http://pkgs.repoforge.org/rrdtool/perl-rrdtool-1.4.7-1.el6.rfx.x86_64.rpm

try yum -y localinstall rrdtool-1.4.7-1.el6.rfx.x86_64.rpm perl-rrdtool-1.4.7-1.el6.rfx.x86_64.rpm

# BUG NEED:
try yum -y install libaio

#mysql:
try wget $MYSQL_MIRROR/MySQL-server-${MYSQL_BUILD}.el6.x86_64.rpm
try wget $MYSQL_MIRROR/MySQL-shared-${MYSQL_BUILD}.el6.x86_64.rpm
# BUG NEED:
try wget $MYSQL_MIRROR/MySQL-client-${MYSQL_BUILD}.el6.x86_64.rpm
try rpm -ivh MySQL-*-${MYSQL_BUILD}.el6.x86_64.rpm

try /sbin/chkconfig --add mysql
try /sbin/chkconfig --level 2345 mysql on
try /etc/init.d/mysql restart
try /usr/bin/mysqladmin -u root password ''
try /usr/bin/mysqladmin -u root -h localhost password ''

#EPEL:
try wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-${EPEL_VER}.noarch.rpm
try rpm -Uvh epel*.rpm

#DOC BUG: do yum install after EPEL:
try yum -y install erlang gmp gnupg liberation-fonts libgcj.x86_64 libgomp libxslt memcached net-snmp net-snmp-utils perl-DBI rabbitmq-server tk unixODBC

try chkconfig rabbitmq-server on
try chkconfig memcached on
try chkconfig snmpd on
try service rabbitmq-server start
try service memcached start
try service snmpd start

# pre-zenoss BUG
try yum -y install dmidecode liberation-fonts-common liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts sysstat 

try wget http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$BUILD/zenoss-$BUILD.el6.x86_64.rpm
try rpm -ivh zenoss-$BUILD.el6.x86_64.rpm
try service zenoss start

try wget http://downloads.sourceforge.net/project/zenoss/zenoss-alpha/$BUILD/zenoss-core-zenpacks-$BUILD.el6.x86_64.rpm
try rpm -ivh zenoss-core-zenpacks-$BUILD.el6.x86_64.rpm

