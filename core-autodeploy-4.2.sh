#!/bin/bash
####################################################
#
# A simple script to auto-install Zenoss Core 4.2
#
# This script should be run on a base install of
# CentOS 5/6 or RHEL 5/6.
#
###################################################

try() {
	"$@"
	if [ $? -ne 0 ]; then
		echo "Command failure: $@"
		exit 1
	fi
}

#Now that RHEL6 RPMs are released, lets try to be smart and pick RPMs based on that
if [ -f /etc/redhat-release ]; then
	elv=`cat /etc/redhat-release | gawk 'BEGIN {FS="release "} {print $2}' | gawk 'BEGIN {FS="."} {print $1}'`
	#EnterpriseLinux Version String. Just a shortcut to be used later
	els=el$elv
else
	#Bail
	echo "Unable to determine version. I can't continue"
	exit 1
fi
cd /tmp

#Disable SELinux:

echo "Disabling SELinux..."
if [ -e /selinux/enforce ]; then
	echo 0 > /selinux/enforce
fi

if [ -e /etc/selinux/config ]; then
	sed -i -e 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

# Defaults for user provided input
arch="x86_64"
# ftp mirror for MySQL to use for version auto-detection:
mysql_ftp_mirror="ftp://mirror.anl.gov/pub/mysql/Downloads/MySQL-5.5/"

# Auto-detect latest build:
build=4.2.0
zenoss_base_url="http://downloads.sourceforge.net/project/zenoss/zenoss-4.2/zenoss-$build"
zenpack_base_url="http://downloads.sourceforge.net/project/zenoss/zenpacks-4.2/zenpacks-$build"
zenoss_rpm_file="zenoss-$build.$els.$arch.rpm"
zenpack_rpm_file="zenoss-core-zenpacks-$build.$els.$arch.rpm"

# Let's grab Zenoss first...

zenoss_gpg_key="http://dev.zenoss.org/yum/RPM-GPG-KEY-zenoss"
for url in $zenoss_base_url/$zenoss_rpm_file $zenpack_base_url/$zenpack_rpm_file; do
	if [ ! -f "${url##*/}" ];then
		echo "Downloading ${url##*/}..."
		try wget -N $url
	fi
done

if [ `rpm -qa gpg-pubkey* | grep -c "aa5a1ad7-4829c08a"` -eq 0  ];then
	echo "Importing Zenoss GPG Key"
	try rpm --import $zenoss_gpg_key
fi

echo "Auto-detecting most recent MySQL Community release"
try rm -f .listing
try wget --no-remove-listing $mysql_ftp_mirror >/dev/null 2>&1
if [ -e /tmp/.listing ]; then
	# note: .listing won't be created if you going thru a proxy server(e.g. squid)
	mysql_v=`cat .listing | awk '{ print $9 }' | grep MySQL-client | grep $els.x86_64.rpm | sort | tail -n 1`
	# tweaks to isolate MySQL version:
	mysql_v="${mysql_v##MySQL-client-}"
	mysql_v="${mysql_v%%.$els.*}"
	echo "Auto-detected version $mysql_v"
fi
if [ "${mysql_v:0:1}" != "5" ]; then
	# sanity check
	echo "Auto-detect failure: $mysql_v - falling back to 5.5.25-1"
	mysql_v="5.5.25-1"
fi
rm -f .listing

echo "Ensuring This server is in a clean state before we start"
mysql_installed=0
if [ `rpm -qa | egrep -c -i "^mysql-(libs|server)?"` -gt 0 ]; then
	if [ `rpm -qa | egrep -i "^mysql-(libs|server)?" | grep -c -v 5.5` -gt 0 ]; then
		echo "It appears you already have an older version of MySQL packages installed"
		echo "I'm too scared to continue. Please remove the following existing MySQL Packages:"
		rpm -qa | egrep -i "^mysql-(libs|server)?"
		exit 1
	else
		if [ `rpm -qa | egrep -c -i "mysql-server"` -gt 0 ];then
			echo "It appears MySQL 5.5 server is already installed. MySQL Installation  will be skipped"
			mysql_installed=1
		else
			echo "It appears you have some MySQL 5.5 packages, but not MySQL Server. I'll try to install"
		fi
	fi
fi

echo "Ensuring Zenoss RPMs are not already present"
if [ `rpm -qa | grep -c -i zenoss` -gt 0 ]; then
	echo "I see Zenoss Packages already installed. I can't handle that"
	exit 1
fi

jre_file="jre-6u31-linux-x64-rpm.bin"
jre_url="http://javadl.sun.com/webapps/download/AutoDL?BundleId=59622"
mysql_client_rpm="MySQL-client-$mysql_v.linux2.6.x86_64.rpm"
mysql_server_rpm="MySQL-server-$mysql_v.linux2.6.x86_64.rpm"
mysql_shared_rpm="MySQL-shared-$mysql_v.linux2.6.x86_64.rpm"
epel_rpm_url=http://dl.fedoraproject.org/pub/epel/$elv/$arch

echo "Enabling EPEL Repo"
wget -r -l1 --no-parent -A 'epel*.rpm' $epel_rpm_url
try yum -y --nogpgcheck localinstall */pub/epel/$elv/$arch/epel-*.rpm

echo "Installing Required Packages"
#try yum -y install \
#libaio tk unixODBC \
#nagios-plugins nagios-plugins-dig nagios-plugins-dns \
#nagios-plugins-http nagios-plugins-ircd nagios-plugins-ldap \
#nagios-plugins-ntp nagios-plugins-ping nagios-plugins-rpc nagios-plugins-tcp \
#erlang memcached perl-DBI net-snmp \
#net-snmp-utils gmp libgomp libgcj.$arch libxslt dmidecode sysstat

try wget http://www.rabbitmq.com/releases/rabbitmq-server/v2.8.4/rabbitmq-server-2.8.4-1.noarch.rpm
try yum -y --nogpgcheck localinstall rabbitmq-server-2.8.4-1.noarch.rpm

#Some Package names are depend on el release
#if [ "$elv" == "5" ]; then
#	try yum -y install liberation-fonts
#elif [ "$elv" == "6" ]; then
#	try yum -y install liberation-fonts-common pkgconfig liberation-mono-fonts liberation-sans-fonts liberation-serif-fonts
#fi

echo "Downloading Files"
if [ `rpm -qa | grep -c -i ^openjdk` -eq 0 ]; then
	if [ ! -f $jre_file ];then
		echo "Downloading Oracle JRE"
		try wget -N -O $jre_file $jre_url
		try chmod +x $jre_file
	fi
	if [ `rpm -qa | grep -c jre` -eq 0 ]; then
		echo "Installating JRE"
		try ./$jre_file
	fi
else
	echo "Appears you already have a JRE installed. I'm not going to install another one"
fi

echo "Downloading and installing MySQL RPMs"
if [ $mysql_installed -eq 0 ]; then
	#Only install if MySQL Is not already installed
	for file in $mysql_client_rpm $mysql_server_rpm $mysql_shared_rpm;
	do
		if [ ! -f $file ];then
			try wget -N http://cdn.mysql.com/Downloads/MySQL-5.5/$file
		fi
		if [ ! -f $file ];then
			echo "Failed to download $file. I can't continue"
			exit 1
		fi
		rpm_entry=`echo $file | sed s/.x86_64.rpm//g | sed s/.i386.rpm//g | sed s/.i586.rpm//g`
		if [ `rpm -qa | grep -c $rpm_entry` -eq 0 ];then
			try yum -y --nogpgcheck localinstall $file
		fi
	done
fi

#echo "Installing Zenoss Dependency Repo"
#There is no EL6 rpm for this as of now. I'm not even entirelly sure we really need it if we have epel
#rpm -ivh http://deps.zenoss.com/yum/zenossdeps.el5.noarch.rpm

# Scientific Linux 6 includes AMQP daemon -> qpidd stop it before starting rabbitmq
if [ -e /etc/init.d/qpidd ]; then
       try /sbin/service qpidd stop
       try /sbin/chkconfig qpidd off
fi

echo "Ensuring net-snmp and memcached are installed"
try yum -y install memcached net-snmp
 
echo "Configuring and Starting some Base Services"
for service in rabbitmq-server memcached snmpd mysql; do
	try /sbin/chkconfig $service on
	try /sbin/service $service start
done

echo "Installing optimal /etc/my.cnf settings"
cat >> /etc/my.cnf << EOF
[mysqld]
max_allowed_packet=16M
innodb_buffer_pool_size = 256M
innodb_additional_mem_pool_size = 20M
EOF

echo "Configuring MySQL"
try /sbin/service mysql restart
try /usr/bin/mysqladmin -u root password ''
try /usr/bin/mysqladmin -u root -h localhost password ''

# set up rrdtool, etc.

echo "Setting up rpmforge repo..."
try wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.$els.rf.$arch.rpm
try yum -y localinstall rpmforge-release-0.5.2-2.$els.rf.$arch.rpm
	
echo "Installing rrdtool"
try yum -y --enablerepo='rpmforge*' install rrdtool-1.4.7

echo "Installing Zenoss"
try yum -y localinstall $zenoss_rpm_file

try /sbin/service zenoss start

echo "Installing Core ZenPacks - this takes several minutes..."
try yum -y localinstall $zenpack_rpm_file

echo
echo "Zenoss auto-install complete!"
echo
echo "Visit http://127.0.0.1:8080 in a Web browser to complete setup."

