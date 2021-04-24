#!/bin/bash

#########################################################################################
#
#  Configuration script for setting up database service for web application environment
#  author Kozyrev SA 2021
#
#########################################################################################

#----------------------------------------------------------------------------------------
# Init local variables
#----------------------------------------------------------------------------------------

# Installation log file
LOG_FILE="/var/log/init_dbapp_service.log"

# Directory for coping update data into web app VM
FILES_DIR="/tmp"

# Include settings file
. ${FILES_DIR}/webapp_settings.conf
#========================================================================================

echo "***********************************************************************************************" >> ${LOG_FILE}
echo "*    Starting the process of configuring the databse service CS-Cart" >> ${LOG_FILE}
echo "*      `date '+DATE: %d/%m/%y'`" >> ${LOG_FILE}
echo "*      `date '+TIME: %H:%M:%S'`" >> ${LOG_FILE}
echo "***********************************************************************************************" >> ${LOG_FILE}

#----------------------------------------------------------------------------------------
# Update and Install software packages
#----------------------------------------------------------------------------------------
echo "" >> ${LOG_FILE}
echo " >>> INSTALL SYSTEM PAKAGES..." >> ${LOG_FILE}
echo "" >> ${LOG_FILE}
yum update -y  2>&1 1>>${LOG_FILE}
yum upgrade -y  2>&1 1>>${LOG_FILE}
yum install mc net-tools zip unzip redis mysql-server -y 2>&1 1>>${LOG_FILE}
#========================================================================================

IS_MYSQL_SERVER_INSTALL="`yum list --installed | grep -c '^mysql-server'`"

if [ "${IS_MYSQL_SERVER_INSTALL}" -eq "1" ]; then
    echo "" >> ${LOG_FILE}
    echo " >>> START DATABASE SERVICE..." >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    systemctl start mysqld.service 2>&1 1>>${LOG_FILE}

    #----------------------------------------------------------------------------------------
    # Init database settings
    #----------------------------------------------------------------------------------------
    echo "" >> ${LOG_FILE}
    echo " >>> INIT DATABASE SETTINGS..." >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}

    mysqladmin --user=root password ${MYSQL_ROOT_PAS} 2>&1 1>>${LOG_FILE}

    mysql -u root -p${MYSQL_ROOT_PAS} -e "CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PAS}';
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
        CREATE DATABASE ${MYSQL_DB_NAME};
        CREATE USER '${MYSQL_USER_NAME}'@'${IP_VM_WEB_APP}' IDENTIFIED BY '${MYSQL_USER_PAS}';
        GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME}.* TO '${MYSQL_USER_NAME}'@'${IP_VM_WEB_APP}' WITH GRANT OPTION;
        FLUSH PRIVILEGES;" 2>&1 1>>${LOG_FILE}
    #========================================================================================
    rm -Rf ${FILES_DIR}/webapp_settings.conf

    systemctl enable mysqld.service

    echo "====================DBAPP CONFIGURE DONE!!!==================================" 2>&1 1>>${LOG_FILE}
else
    echo " >>>>>>>>>>>>>>> ERROR! MYSQL-SERVER PACKAGE NOT INSTALL..." 2>&1 1>>${LOG_FILE}
    echo " >>>>>>>>>>>>>>> DBAPP NOT CONFIGURE..." 2>&1 1>>${LOG_FILE}
    exit -1
fi
