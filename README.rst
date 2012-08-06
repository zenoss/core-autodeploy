core-autodeploy
===============

Auto-deployment scripts for Zenoss Core 4 on CentOS 5/6.x or Red Hat Enterprise
Linux 5/6.x. A 64-bit build is required. Version 6.x of RHEL or CentOS is recommended.

The script included in this directory will automatically deploy Zenoss Core 4
for you. It will download Java, MySQL, Zenoss Core 4, all RPM dependencies, and
install everything including the Zenoss Core ZenPacks. To use, perform the
following steps on a fresh CentOS or Red Hat Enterprise Linux installation::

 # cd /tmp
 # chmod +x core-autodeploy-4.2.sh
 # ./core-autodeploy-4.2.sh

The script will take several minutes (around 10-30) to complete. When done, you
should have a fully functioning Zenoss Core install and should be able to visit
the following URL in a Web browser to perform additional configuration:

http://<IP of server>:8080

Notes
~~~~~

The script will auto-detect the current version of MySQL 5.5 Community and
install it.

Credits
~~~~~~~

Thanks to David Petzel for writing the original Core 4 beta auto-deploy script,
which was part of zenoss_zca_utils.
