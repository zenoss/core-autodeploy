core-autodeploy
===============

Auto-deployment scripts for Zenoss Core 4 alpha/beta on CentOS 6/Red Hat Enterprise Linux 6.

The script included in this directory will automatically deploy Zenoss Core 4
for you. It will download Java, MySQL Zenoss Core 4, all RPM dependencies, and
install everything including the Zenoss Core ZenPacks. To use, perform the
following steps on a fresh CentOS 6/Red Hat Enterprise Linux 6 installation::

 # cd /tmp
 # chmod +x path/to/el6-auto.sh
 # path/to/el6-auto.sh

The script will take several minutes (around 10-15) to complete. When done, you
should have a fully functioning Zenoss Core install and should be able to visit
the following URL in a Web browser to perform additional configuration:

http://<IP of server>:8080

Notes
~~~~~

The script has the Zenoss build to install hard-coded at the top of the script, in the
``BUILD`` variable.

The script will auto-detect the current version of MySQL 5.5 Community and install it.

Currently, the EPEL package repository version to use is hard-coded and may need to be
tweaked as EPEL is updated. This will be improved upon in future versions of the script.
