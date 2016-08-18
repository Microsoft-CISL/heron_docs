#!/bin/bash

############################################################
# Created by t-pagar@microsoft.com - pgaref.github.io	   #
# Install and configure stuff 			   	               #
############################################################


#This the remote dir to be used - common in all machines
ROOT_PASS=cisllab
CISL_WS=/home/hadoop/yarn-dev-panos

TIMEOUT=5
THREADS=1

slaves=cisl-linux-0[31-39]
RM_NODE=cisl-linux-030 #Where the resource manager is going to run
all_machines=${RM_NODE},${slaves}

# Copy everything from this dir on Cobbler, should be flat at present
SRC_DIR=/home/hadoop/yarn-dev-panos/src_files

#########################
# Configuring HERON     #
#                       #
#########################

function check_centos_heron_dependencies(){
    strings /usr/lib64/libstdc++.so.6 | grep GLIBC
}

function fix_centos_heron_dependencies(){
 echo "Fixing Heron CentOS Deps - GCC-GLIBC-LIBUNWIND"

 pdsh -R exec -f $THREADS -w ${all_machines} sshpass -p $ROOT_PASS ssh -t -o ConnectTimeout=$TIMEOUT -l root %h  "( . $CISL_WS/env.sh -q; \
        yum update --skip-broken -y; \
        yum install unzip libunwind -y; \
        yum groupinstall \"Development tools\" -y; yum install glibc-devel.i686 glibc-i686 -y; \
        cd /tmp; wget http://ftp.gnu.org/gnu/glibc/glibc-2.16.0.tar.gz; tar -xvzf glibc-2.16.0.tar.gz; cd glibc-2.16.0; \
        mkdir glibc-build; cd glibc-build; ../configure --prefix='/usr'; \
        sed -i '172s/.*/if (\\\/Q\$ld_so_name\\E\/) {/' ../scripts/test-installation.pl; \
        make && make install; \
        cd /tmp; wget ftp://ftp.gwdg.de/pub/misc/gcc/releases/gcc-4.8.4/gcc-4.8.4.tar.gz; \
        tar -xvf gcc-4.8.4.tar.gz;  cd gcc-4.8.4; ./contrib/download_prerequisites ; \
        mkdir objdir; cd objdir; ../configure --prefix=/opt/gcc-4.8.4; \
        make && make install; \
        mv -f /usr/lib64/libstdc++.so.6 /usr/lib64/libstdc++.so.6.bak; \
        mv -f /opt/gcc-4.8.4/lib64/libstdc++.so.6 /usr/lib64/libstdc++.so.6; \
        mv -f /opt/gcc-4.8.4/lib64/libstdc++.so.6.0.19 /usr/lib64/libstdc++.so.6.0.19; \
 )"
}


function install_python27(){
 echo "Installing Python 2.7"
 pdsh -R exec -f $THREADS -w ${all_machines} sshpass -p $ROOT_PASS ssh -t -o ConnectTimeout=$TIMEOUT -l root %h  "( . $CISL_WS/env.sh -q; \
        wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz; xz -d Python-2.7.6.tar.xz; \
        tar -xvf Python-2.7.6.tar; cd Python-2.7.6; ./configure --prefix=/usr/local; \
        make; make altinstall; ln -s /usr/local/bin/python2.7 /usr/bin/; \
 )"
}

function install_java8(){
 echo "Installing Java 8"
 pdsh -R exec -f $THREADS -w ${all_machines} sshpass -p $ROOT_PASS ssh -t -o ConnectTimeout=$TIMEOUT -l root %h  "( . $CISL_WS/env.sh -q; \
        yum install java-1.8.0-openjdk-devel-1:1.8.0.91-1.b14.el6.x86_64 -y; \
 )"
}


#########################
# The command line help #
#########################
display_usage() {
    echo "=================================================================="
    echo "Usage: $0 [option...]" >&2
    echo "   -fix-heron-deps       Fix Heron Deps on CentOS"
    echo "   -install-python       Installs Python 2.7 on CentOS"
    echo "=================================================================="
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}


case "$1" in
  (-install-python)
    install_python27
    exit
    ;;
    (-fix-heron-deps)
    fix_centos_heron_dependencies
    exit
    ;;
  ("")
    display_usage
    exit
    ;; # Run the regular script
  (*)
    echo "Unknown flag: \"$1\""
    display_usage
    exit
    ;;
esac

