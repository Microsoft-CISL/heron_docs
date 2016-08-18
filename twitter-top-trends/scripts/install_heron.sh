#!/bin/bash

############################################################
# Created by t-pagar@microsoft.com - pgaref.github.io	   #
# Summer 2016						   #
# Common "HERON functionality 				   #
############################################################

#This the Remote Dir to be used - Common in all machines
CISL_WS=/home/hadoop/yarn-dev-panos

# Current Version!
HADOOP_VERSION=3.0.0-alpha2-SNAPSHOT
HERON_INSTALL_DIR=/home/hadoop/.heron
ZKHOST=cisl-linux-030 #Where the resource manager is running


function heron_state_config(){
    # Customize heron config files for this cluster
    STATE_MANAGER_CONF_FILE=$HERON_INSTALL_DIR/conf/yarn/statemgr.yaml
    echo "Creating state manager conf file: $STATE_MANAGER_CONF_FILE"

cat > $STATE_MANAGER_CONF_FILE <<EOL
heron.class.state.manager: com.twitter.heron.statemgr.zookeeper.curator.CuratorStateManager
heron.statemgr.connection.string: "$ZKHOST:2181"
heron.statemgr.root.path: "/heron"
heron.statemgr.zookeeper.is.initialize.tree: True
heron.statemgr.zookeeper.session.timeout.ms: 30000
heron.statemgr.zookeeper.connection.timeout.ms: 30000
heron.statemgr.zookeeper.retry.count: 10
heron.statemgr.zookeeper.retry.interval.ms: 10000
EOL

    TOOLS_CONF_FILE=${HERON_INSTALL_DIR}tools/conf/heron_tracker.yaml
    echo "Creating tools conf file: $TOOLS_CONF_FILE"

cat > $TOOLS_CONF_FILE <<EOL
statemgrs:
  -
    type: "zookeeper"
    name: "localzk"
    hostport: "$ZKHOST:2181"
    rootpath: "/heron"
    tunnelhost: "localhost"
EOL

}

function heron_configure_classpath(){
    # Copy jars needed by client till heron supports classpaths
    TEMP_CLASSPATH_DIR=$HERON_INSTALL_DIR/lib/scheduler
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jackson-mapper-asl*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jackson-core-asl*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jackson-jaxrs*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jackson-xc*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/commons-collections*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/commons-configuration*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/commons-compress*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/commons-logging*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/commons-lang*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/htrace-core*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/avro*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jersey-core*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/lib/jersey-client*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/jetty-util*.jar $TEMP_CLASSPATH_DIR

    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/hadoop-yarn-api*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/hadoop-yarn-client*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/hadoop-yarn-common*.jar $TEMP_CLASSPATH_DIR

    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/hadoop-common*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/hadoop-auth*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/tools/lib/hadoop-azure*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/hdfs/lib/hadoop-hdfs*.jar $TEMP_CLASSPATH_DIR
    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/hdfs/lib/netty-all*.jar $TEMP_CLASSPATH_DIR

#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/lib/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/common/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/hdfs/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/hdfs/lib/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/mapreduce/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/lib/*.jar $TEMP_CLASSPATH_DIR
#    cp $CISL_WS/hadoop-$HADOOP_VERSION/share/hadoop/yarn/*.jar $TEMP_CLASSPATH_DIR

    cp $CISL_WS/conf/yarn-site.xml . && jar uf $TEMP_CLASSPATH_DIR/hadoop-yarn-common-$HADOOP_VERSION.jar yarn-site.xml && rm yarn-site.xml
    cp $CISL_WS/conf/core-site.xml . && jar uf $TEMP_CLASSPATH_DIR/hadoop-common-$HADOOP_VERSION.jar core-site.xml && rm core-site.xml
    chmod +r $TEMP_CLASSPATH_DIR/hadoop-yarn-common-$HADOOP_VERSION.jar $TEMP_CLASSPATH_DIR/hadoop-common-$HADOOP_VERSION.jar
#    rm $TEMP_CLASSPATH_DIR/commons-cli-1.2*.jar
#    rm $TEMP_CLASSPATH_DIR/curator-*jar
}

function heron_install_ubuntu(){
    wget https://github.com/twitter/heron/releases/download/0.14.2/heron-tools-install-0.14.2-ubuntu.sh
    wget https://github.com/twitter/heron/releases/download/0.14.2/heron-client-install-0.14.2-ubuntu.sh
    chmod +x ./heron-client-install-0.14.2-ubuntu.sh
    chmod +x ./heron-tools-install-0.14.2-ubuntu.sh
    ./heron-client-install-0.14.2-ubuntu.sh --user
    export PATH=$PATH:~/bin
    ./heron-tools-install-0.14.2-ubuntu.sh --user
    heron version
    rm ./heron-client-install-0.14.2-ubuntu.sh ./heron-tools-install-0.14.2-ubuntu.sh
}

# Use heron-0.14.1 for now to avoid know issues in 14.2!!
function heron_install_centos(){
    # Python 2.7 installation path
    export PATH="/usr/local/bin:$PATH"

    wget https://github.com/twitter/heron/releases/download/0.14.1/heron-tools-install-0.14.1-centos.sh
    wget https://github.com/twitter/heron/releases/download/0.14.1/heron-client-install-0.14.1-centos.sh
    chmod +x ./heron-client-install-0.14.1-centos.sh
    chmod +x ./heron-tools-install-0.14.1-centos.sh
    ./heron-client-install-0.14.1-centos.sh --user
    export PATH=$PATH:~/bin
    ./heron-tools-install-0.14.1-centos.sh --user
    heron version
    rm ./heron-client-install-0.14.1-centos.sh ./heron-tools-install-0.14.1-centos.sh
}

function heron_submit_local_exclamationTopology(){
    export PATH=$PATH:~/bin
    heron submit local \
        ${HERON_INSTALL_DIR}/examples/heron-examples.jar \
        com.twitter.heron.examples.ExclamationTopology \
        ExclamationTopology \
        --deploy-deactivated
}

function heron_submit_yarn_exclamationTopology(){
    export PATH=$PATH:~/bin
    heron submit yarn ${HERON_INSTALL_DIR}/examples/heron-examples.jar \
           com.twitter.heron.examples.ExclamationTopology ExclamationTopology
}

function heron_submit_yarn_twitterTrendsTopology(){
    export PATH=$PATH:~/bin
    heron submit yarn TwitterTrendsTopology-1.0-SNAPSHOT.jar \
           com.microsoft.cisl.hashtrend.TwitterRollingTrendsTopology TwitterRollingTrendsTopology
}

function heron_activate_local_topology(){
    export PATH=$PATH:~/bin
    heron activate local ExclamationTopology
}

function heron_deactivate_local_topology(){
    export PATH=$PATH:~/bin
    heron deactivate local ExclamationTopology
}

function heron_kill_local_topology(){
    export PATH=$PATH:~/bin
    heron kill local ExclamationTopology
}

function heron_tracker(){
    export PATH=$PATH:~/bin
    nohup heron-tracker &> heron-tracker.out &
}

function heron_ui(){
    export PATH=$PATH:~/bin
    nohup heron-ui &> heron-ui.out &
}

function heron_kill_all(){
    ps aux | grep heron | awk '{print $2}'|xargs kill -9
#    rm -rf ~/.herondata/
}
#########################
# The command line help #
#########################
display_usage() {
    echo "=================================================================="
    echo "Usage: $0 [option...]" >&2
    echo "   -heron-install-ubuntu      Install Heron Client and Tools on Ubuntu"
    echo "   -heron-install-centos      Install Heron Client and Tools on CentOs"
    echo "   -heron-configure-client    Configure Client Classpath Jar files"
    echo "   -heron-ui                  Start Heron UI"
    echo "   -heron-tracker             Start Heron Tracker"
    echo "   -heron-submit-yarn-trends  Submits a YARN TwitterTrendsTopology"
    echo "   -heron-submit-yarn         Submits a YARN ExclamationTopology"
    echo "   -heron-submit-local        Submits a local ExclamationTopology"
    echo "   -heron-activate-local      Activates a local ExclamationTopology"
    echo "   -heron-deactivate-local    Deactivates a local ExclamationTopology"
    echo "   -heron-kill-local          Kills a local ExclamationTopology"
    echo "   -heron-kill-all            Kills all heron tasks"
    echo "=================================================================="
    echo
    # echo some stuff here for the -a or --add-options
    exit 1
}


case "$1" in
  (-heron-install-ubuntu)
    heron_install_ubuntu
    exit
    ;;
  (-heron-install-centos)
    heron_install_centos
    exit
    ;;
  (-heron-configure-client)
    heron_configure_classpath
    heron_state_config
    exit
    ;;
  (-heron-ui)
    heron_ui
    exit
    ;;
  (-heron-tracker)
    heron_tracker
    exit
    ;;
  (-heron-submit-yarn-trends)
    heron_submit_yarn_twitterTrendsTopology
    exit
    ;;
  (-heron-submit-yarn)
    heron_submit_yarn_exclamationTopology
    exit
    ;;
  (-heron-submit-local)
    heron_submit_local_exclamationTopology
    exit
    ;;
  (-heron-activate-local)
    heron_activate_local_topology
    exit
    ;;
  (-heron-deactivate-local)
    heron_deactivate_local_topology
    exit
    ;;
  (-heron-kill-local)
    heron_kill_local_topology
    exit
    ;;
  (-heron-kill-all)
    heron_kill_all
    exit
    ;;
  (*)
    echo "Unknown option: \"$1\""
    display_usage
    exit
    ;;
esac