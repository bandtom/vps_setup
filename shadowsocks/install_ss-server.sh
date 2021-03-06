#!/bin/bash

# 定义文字颜色
Green="\033[32m"  && Red="\033[31m" && GreenBG="\033[42;37m" && RedBG="\033[41;37m" && Font="\033[0m"

echo -e "${Green}:: Quick install Shadowsocks-libev For Linux X64 (Debian 8/9/10 Ubuntu 16/18/19 Centos 7) ${Font}"
echo -e "${Green}:: Compile/Update: ${RedBG} bash <(curl -L -s git.io/fhExJ) update ${Font}"

def_install(){
    # Download the binary release of Pure Compilation.
    wget -O /tmp/ss.tgz https://git.io/ss.tgz
    tar xvf  /tmp/ss.tgz -C /

    echo "/usr/local/lib" > /etc/ld.so.conf.d/ss-libev.conf
    ldconfig
    export PATH=$PATH:/usr/local/bin
    rm /tmp/ss.tgz
}

old_def_install(){
    if [[ ${release} == "centos" ]]; then
        # 安装所需运行库 Centos 7
        yum update -y
        yum install -y  libev-devel c-ares-devel  mbedtls-devel libsodium-devel
    else
        # 安装所需运行库 Debian 9 & Ubuntu 18
        apt update
        apt install -y  libev-dev libc-ares-dev  libmbedtls-dev libsodium-dev
    fi

    # 下载 ss-server 对应各系统
    wget https://raw.githubusercontent.com/hongwenjun/vps_setup/master/shadowsocks/${release}/ss-server
    chmod +x  ss-server  &&  mv ss-server /usr/local/bin/ss-server
}

debian_ubuntu_dev(){
    # Debian 9 & Ubuntu 安装编译环境和运行库
    apt update
    apt install -y gcc g++ git gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libc-ares-dev automake libmbedtls-dev libsodium-dev
}

centos7_dev(){
    # Cetons 安装编译环境和运行库
    yum install epel-release git -y
    yum groupinstall "Development Tools" -y
    yum install gcc gettext autoconf libtool automake make pcre-devel asciidoc xmlto c-ares-devel libev-devel libsodium-devel mbedtls-devel -y
}

inst_ss-server(){
    # 下载shadowsocks代码
    git clone --recursive https://github.com/shadowsocks/shadowsocks-libev --depth=1
    cd shadowsocks-libev
    git submodule update --init --recursive

    # 编译安装ss-server
    ./autogen.sh
    ./configure
    make
    make install
    cd ..
    # rm shadowsocks-libev -rf
}

# 检查系统
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
    bit=`uname -m`
}

sysctl_config() {
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}

# 开启 BBR
sysctl_config
lsmod | grep bbr

# 判断系统安装软件
update_ss-server(){
    if [[ ${release} == "centos" ]]; then
        centos7_dev
        inst_ss-server
    fi

    if [[ ${release} == "ubuntu" ]]; then
        debian_ubuntu_dev
        inst_ss-server
    fi

    if [[ ${release} == "debian" ]]; then
        debian_ubuntu_dev
        inst_ss-server
    fi
}

# 安装 ss-server
check_sys
if [[ $# > 0 ]]; then
    key="$1"
    case $key in
        update)
        update_ss-server
        ;;
    esac
else
    if [ ! -f '/usr/local/bin/ss-server' ]; then
        def_install
    fi

    # 如果运行库错误,编译/更新安装
    /usr/local/bin/ss-server -v  >/dev/null 2>&1
    if [ $? == 127 ]; then
        update_ss-server
    fi

fi
