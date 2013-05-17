cat <<EOF
Welcome to the Zenoss Core auto-deploy script!

This auto-deploy script installs the Oracle Java Runtime Environment (JRE).
To continue, please review and accept the Oracle Binary Code License Agreement
for Java SE. 

Press Enter to continue.
EOF
read
less licenses/Oracle-BCLA-JavaSE
while true; do
    read -p "Do you accept the Oracle Binary Code License Agreement for Java SE?" yn
    case $yn in
        [Yy]* ) echo "Install continues...."; break;;
        [Nn]* ) echo "Installation aborted."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

