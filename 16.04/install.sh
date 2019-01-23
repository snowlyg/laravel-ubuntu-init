#!/bin/bash
set -e

CURRENT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
source ${CURRENT_DIR}/../common/common.sh

# [ $(id -u) != "0" ] && { ansi -n --bold --bg-red "请用 root 账户执行本脚本"; exit 1; }

MYSQL_ROOT_PASSWORD=`random_string`

function init_system {
    export LC_ALL="en_US.UTF-8"
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
    locale-gen en_US.UTF-8
    locale-gen zh_CN.UTF-8

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

   sudo apt-get update
   sudo apt-get install -y software-properties-common

    init_alias
}

function init_alias {
    alias sudowww > /dev/null 2>&1 || {
        echo "alias sudowww='sudo -H -u ${WWW_USER} sh -c'" >> ~/.bash_aliases
    }
}

function init_repositories {
    add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:nginx/stable
    grep -rl ppa.launchpad.net /etc/apt/sources.list.d/ | xargs sed -i 's/ppa.launchpad.net/launchpad.proxy.ustclug.org/g'

    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
    echo 'deb https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb_8.x xenial main' > /etc/apt/sources.list.d/nodesource.list
    echo 'deb-src https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb_8.x xenial main' >> /etc/apt/sources.list.d/nodesource.list

  sudo  apt-get update
}

function install_basic_softwares {
   sudo apt-get install -y curl git build-essential unzip supervisor
}

function install_node_yarn {
  sudo  apt-get install -y nodejs yarn
    sudo -H -u $USER sh -c 'cd ~ && yarn config set registry https://registry.npm.taobao.org'
}

function install_php {
    apt-get install -y php7.2-bcmath php7.2-cli php7.2-curl php7.2-fpm php7.2-gd php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-pgsql php7.2-readline php7.2-xml php7.2-zip php7.2-sqlite3
}

function install_others {
   sudo apt-get remove -y apache2
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"
   sudo apt-get install -y nginx mysql-server redis-server memcached beanstalkd sqlite3
   sudo  chown -R $USER.${WWW_USER_GROUP} /var/www/
   sudo systemctl enable nginx.service
}

function install_composer {
    sudo wget https://dl.laravel-china.org/composer.phar -O /usr/local/bin/composer
    sudo  chmod +x /usr/local/bin/composer
    sudo -H -u $USER sh -c  'cd ~ && composer config -g repo.packagist composer https://packagist.laravel-china.org'
}

function install_valet {
    sudo apt-get install libnss3-tools jq xsel
    composer global require cpriego/valet-linux
    valet install
    valet domain com
}


call_function init_system "正在初始化系统" ${LOG_PATH}
call_function init_repositories "正在初始化软件源" ${LOG_PATH}
call_function install_basic_softwares "正在安装基础软件" ${LOG_PATH}
call_function install_php "正在安装 PHP" ${LOG_PATH}
call_function install_others "正在安装 Mysql / Nginx / Redis / Memcached / Beanstalkd / Sqlite3" ${LOG_PATH}
call_function install_node_yarn "正在安装 Nodejs / Yarn" ${LOG_PATH}
call_function install_composer "正在安装 Composer" ${LOG_PATH}
call_function install_valet "正在安装 Valet" ${LOG_PATH}

ansi --green --bold -n "安装完毕"
ansi --green --bold "Mysql root 密码："; ansi -n --bold --bg-yellow --black ${MYSQL_ROOT_PASSWORD}
ansi --green --bold -n "请手动执行 source ~/.bash_aliases 使 alias 指令生效。"
