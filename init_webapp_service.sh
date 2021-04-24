#!/bin/bash

#############################################################################
#
#  Configuration script for setting up the web application environment
#  author Kozyrev SA 2021
#
#############################################################################

#----------------------------------------------------------------------------
# Init local variables
#----------------------------------------------------------------------------

# Installation log file
LOG_FILE="/var/log/init_webapp_service.log"

# Directory for coping update data into web app VM
FILES_DIR="/tmp"

# Include settings file
. ${FILES_DIR}/webapp_settings.conf

# Address of the main folder web app
WEBAPP_DIR="/var/www/${WEBAPP_NAME}"

# Address of the custom NGINX configuration file for wep app
NGINX_CUSTOM_CFG_FILE="webcscart.com.conf"
#============================================================================

echo "***********************************************************************************************" >> ${LOG_FILE}
echo "*    Starting the process of configuring the web service CS-Cart" >> ${LOG_FILE}
echo "*      `date '+DATE: %d/%m/%y'`" >> ${LOG_FILE}
echo "*      `date '+TIME: %H:%M:%S'`" >> ${LOG_FILE}
echo "***********************************************************************************************" >> ${LOG_FILE}

#----------------------------------------------------------------------------
# Update and Install software packages
#----------------------------------------------------------------------------
echo "" >> ${LOG_FILE}
echo " >>> INSTALL SYSTEM PAKAGES..." >> ${LOG_FILE}
echo "" >> ${LOG_FILE}
yum update -y 2>&1 1>>${LOG_FILE}
yum upgrade -y 2>&1 1>>${LOG_FILE}
yum install epel-release -y 2>&1 1>>${LOG_FILE}
yum install mc git net-tools zip unzip nginx redis -y 2>&1 1>>${LOG_FILE}
yum install php php-common php-fpm php-mysqlnd php-gd php-json php-soap php-xml php-xmlrpc php-mbstring php-zip php-devel php-pear make mysql -y 2>&1 1>>${LOG_FILE}
yum config-manager --set-enabled powertools -y 2>&1 1>>${LOG_FILE}
yum install ImageMagick ImageMagick-devel -y 2>&1 1>>${LOG_FILE}

echo -ne '\n' | pecl install imagick 2>&1 1>>${LOG_FILE}
echo "extension=imagick.so" >> /etc/php.ini
#============================================================================

# Checking installation NGINX
IS_NGINX_INSTALL="`yum list --installed | grep -c '^nginx'`"

if [ "${IS_NGINX_INSTALL}" -ge "1" ]; then
    #----------------------------------------------------------------------------
    # Setting up the system environment
    #----------------------------------------------------------------------------
    echo "" >> ${LOG_FILE}
    echo " >>> SETTING UP SYSTEM ENVIRONMENT..." >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    # Unpack update configuration files
    tar xzvf ${FILES_DIR}/cfg_files.tgz -C ${FILES_DIR} 2>&1 1>>${LOG_FILE}

    # Get count of the CPU for NGINX configuration
    COUNT_CPU="`cat /proc/cpuinfo | grep processor | wc -l`"

    # Set value NGINX worker process by the number installed CPUs
    sed -i "s/worker_processes auto/worker_processes ${COUNT_CPU}/g" ${FILES_DIR}/${NGINX_CFG_FILE} 2>&1 1>>${LOG_FILE}

    # Set values of the custom NGINX configuration file web app
    sed -i "s/root \\/var\\/www\\/webcscart.com/root \\/var\\/www\\/${WEBAPP_NAME}/g" ${FILES_DIR}/${NGINX_CUSTOM_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/access_log  \\/var\\/log\\/nginx\\/webcscart.com_access.log combined/access_log  \\/var\\/log\\/nginx\\/${WEBAPP_NAME}_access.log combined/g" ${FILES_DIR}/${NGINX_CUSTOM_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/error_log   \\/var\\/log\\/nginx\\/webcscart.com_error.log/error_log   \\/var\\/log\\/nginx\\/${WEBAPP_NAME}_error.log/g" ${FILES_DIR}/${NGINX_CUSTOM_CFG_FILE} 2>&1 1>>${LOG_FILE}

    # Set values of the configuration file web app
    sed -i "s/'host' => '192.168.1.16'/'host' => '${IP_VM_DATABASE}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/'name' => 'testdbcsc'/'name' => '${MYSQL_DB_NAME}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/'user' => 'usercsc'/'user' => '${MYSQL_USER_NAME}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/'password' => 'A1qz2wx3ec'/'password' => '${MYSQL_USER_PAS}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/'http_host' => '192.168.1.15'/'http_host' => '${IP_VM_WEB_APP}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}
    sed -i "s/'https_host' => '192.168.1.15'/'https_host' => '${IP_VM_WEB_APP}'/g" ${FILES_DIR}/${WEBAPP_CFG_FILE} 2>&1 1>>${LOG_FILE}

    # Move new main configuration file NGINX
    mv -f ${FILES_DIR}/${NGINX_CFG_FILE} ${NGINX_MAIN_CFG_DIR}/${NGINX_CFG_FILE} 2>&1 1>>${LOG_FILE}

    # Move new custom NGINX configuration file for web app
    mv -f ${FILES_DIR}/${NGINX_CUSTOM_CFG_FILE} ${NGINX_CUSTOM_CFG_DIR}/${WEBAPP_NAME}".conf" 2>&1 1>>${LOG_FILE}

    # Remove other configuration files
    rm -Rf ${NGINX_CUSTOM_CFG_DIR}/php-fpm.conf 2>&1 1>>${LOG_FILE}

    # Set access rules for configuration files
    chmod -R 644 ${NGINX_MAIN_CFG_DIR}/${NGINX_CFG_FILE} 2>&1 1>>${LOG_FILE}
    chmod -R 644 ${NGINX_CUSTOM_CFG_DIR}/${WEBAPP_NAME}".conf" 2>&1 1>>${LOG_FILE}
    #============================================================================

    #----------------------------------------------------------------------------
    # Setting up the web app environment
    #----------------------------------------------------------------------------
    echo "" >> ${LOG_FILE}
    echo " >>> SETTING UP WEB APP ENVIRONMENT..." >> ${LOG_FILE}
    echo "" >> ${LOG_FILE}
    # Create main web app directory
    mkdir -p ${WEBAPP_DIR} 2>&1 1>>${LOG_FILE}

    # Change file SELinux security context on the main folder web app
    chcon -Rt httpd_sys_rw_content_t ${WEBAPP_DIR} 2>&1 1>>${LOG_FILE}

    # Get repository web app - CS-Cart v4.12.2.SP2_ru
    git clone https://github.com/ksajo/tdevops-csc.git ${WEBAPP_DIR} 2>&1 1>>${LOG_FILE}

    # Checking download repository web app CS-Cart
    IS_REPOS_DOWNLOAD="`ls -l ${WEBAPP_DIR} | grep 'total' | awk -F\" \" '{print $2}'`"

    if [ "${IS_REPOS_DOWNLOAD}" -gt "0" ]; then

        # Move new web app configuration file
        mv -f ${FILES_DIR}/${WEBAPP_CFG_FILE} ${WEBAPP_DIR}/install/ 2>&1 1>>${LOG_FILE}

        # Silent install web app
        cd ${WEBAPP_DIR}/install/
        php index.php 2>&1 1>>${LOG_FILE}

        # Set access rules for web app files
        chown -Rf nginx:nginx ${WEBAPP_DIR} 2>&1 1>>${LOG_FILE}

        cd ${WEBAPP_DIR}

        chmod 666 config.local.php 2>&1 1>>${LOG_FILE}
        chmod -R 777 design images var 2>&1 1>>${LOG_FILE}
        find design -type f -print0 | xargs -0 chmod 666 2>&1 1>>${LOG_FILE}
        find images -type f -print0 | xargs -0 chmod 666 2>&1 1>>${LOG_FILE}
        find var -type f -print0 | xargs -0 chmod 666 2>&1 1>>${LOG_FILE}
        chmod 644 design/.htaccess images/.htaccess var/.htaccess var/themes_repository/.htaccess 2>&1 1>>${LOG_FILE}
        chmod 644 design/index.php images/index.php var/index.php var/themes_repository/index.php 2>&1 1>>${LOG_FILE}

        # Set SELinux setting for connect to db by http
        setsebool -P httpd_can_network_connect_db 1 2>&1 1>>${LOG_FILE}
        #============================================================================
        rm -Rf ${FILES_DIR}/cfg_files.tgz ${FILES_DIR}/webapp_settings.conf

        systemctl enable nginx.service

        echo "" >> ${LOG_FILE}
        echo " >>> START WEB SERVICE..." >> ${LOG_FILE}
        echo "" >> ${LOG_FILE}
        systemctl restart nginx.service 2>&1 1>>${LOG_FILE}

        echo "====================WEBAPP CONFIGURE DONE!!!=================================" 2>&1 1>>${LOG_FILE}
    else
        echo " >>>>>>>>>>>>>>> ERROR! REPOSITORY WEB APP NOT DOWNLOAD..." 2>&1 1>>${LOG_FILE}
        echo " >>>>>>>>>>>>>>> WEBAPP NOT CONFIGURE..." 2>&1 1>>${LOG_FILE}
        exit -2
    fi
else
    echo " >>>>>>>>>>>>>>> ERROR! NGINX WEB-SERVER PACKAGE NOT INSTALL..." 2>&1 1>>${LOG_FILE}
    echo " >>>>>>>>>>>>>>> WEBAPP NOT CONFIGURE..." 2>&1 1>>${LOG_FILE}
    exit -1
fi
