package com.microsoft.cisl.hashtrend;

import backtype.storm.Config;
import backtype.storm.LocalCluster;
import backtype.storm.StormSubmitter;
import backtype.storm.generated.AlreadyAliveException;
import backtype.storm.generated.InvalidTopologyException;
import backtype.storm.generated.NotAliveException;
import backtype.storm.topology.TopologyBuilder;
import backtype.storm.tuple.Fields;
import com.microsoft.cisl.hashtrend.bolt.IntermediateHashRankingsBolt;
import com.microsoft.cisl.hashtrend.bolt.RollingHashCountBolt;
import com.microsoft.cisl.hashtrend.bolt.TotalHashTrendRankingsBolt;
import com.microsoft.cisl.hashtrend.spout.TweetStreamSpout;
import com.microsoft.cisl.hashtrend.window.RankableObjectWithFields;
import com.microsoft.cisl.hashtrend.window.Rankings;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;

/**
 * @author  Panagiotis Garefalakis
 * @version 1.0
 *
 * This topology does a continuous computation of the top N words that the topology has seen in terms of cardinality.
 * The top N computation is done in a completely scalable way, and a similar approach could be used to compute things
 * like trending topics or trending images on Twitter.
 **/
public class TwitterRollingTrendsTopology {

    private static final Logger LOG = Logger.getLogger(TwitterRollingTrendsTopology.class);
    private static final int DEFAULT_RUNTIME_IN_SECONDS = 60;
    private static int DEFAULT_PARALLELISM = 4;
    private static final int TOP_N = 5;

    private final TopologyBuilder builder;
    private final String topologyName;
    private final Config topologyConfig;
    private final int runtimeInSeconds;


    public TwitterRollingTrendsTopology(String topologyName){
        builder = new TopologyBuilder();
        this.topologyName = topologyName;
        topologyConfig = createTopologyConfiguration();
        this.runtimeInSeconds = DEFAULT_RUNTIME_IN_SECONDS;
        try {
            wireTopology();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    private static Config createTopologyConfiguration() {
        Config conf = new Config();
        conf.setDebug(true);
        conf.setMaxSpoutPending(10);
        conf.put(Config.TOPOLOGY_WORKER_CHILDOPTS, "-XX:+HeapDumpOnOutOfMemoryError");
        conf.registerSerialization(Rankings.class);
        conf.registerSerialization(RankableObjectWithFields.class);
        conf.setFallBackOnJavaSerialization(true);
        conf.setContainerCpuRequested(1);
        conf.setComponentRam("tweet", 512L * 1024 * 1024);
        conf.setComponentRam("obj", 512L * 1024 * 1024);
        //Number of Stream Managers In the Topology
        conf.setNumStmgrs(DEFAULT_PARALLELISM);
        return conf;
    }

    private void wireTopology() throws InterruptedException {
        String spoutId = "tweetStreamer";
        String counterId = "hashCounter";
        String intermediateRankerId = "hashIntermediateRanker";
        String totalRankerId = "hashFinalRanker";

        builder.setSpout(spoutId, new TweetStreamSpout(), 1);
        builder.setBolt(counterId, new RollingHashCountBolt(60, 4), DEFAULT_PARALLELISM)
                .fieldsGrouping(spoutId, new Fields("tweet"));
        builder.setBolt(intermediateRankerId, new IntermediateHashRankingsBolt(TOP_N), DEFAULT_PARALLELISM)
                .fieldsGrouping(counterId, new Fields("obj"));
        builder.setBolt(totalRankerId, new TotalHashTrendRankingsBolt(TOP_N)).globalGrouping(intermediateRankerId);
    }

    private void runLocally(String topologyName) throws AlreadyAliveException, InvalidTopologyException {
        LocalCluster cluster = new LocalCluster();
        cluster.submitTopology(topologyName, topologyConfig, builder.createTopology());
    }

    private void runRemotely(String topologyName ){
        try {
            StormSubmitter.submitTopology(topologyName, topologyConfig, builder.createTopology());
        } catch (AlreadyAliveException e) {
            e.printStackTrace();
        } catch (InvalidTopologyException e) {
            e.printStackTrace();
        }
    }




    /**
     * Main method
     */
    public static void main(String[] args) throws AlreadyAliveException, InvalidTopologyException, NotAliveException {

        String topologyName = "trendingHashtags";
        boolean runLocally = true;
        if (args.length >= 1) {
            runLocally = false;
        }

        LOG.info(" Topology name: " + topologyName + "RunLocally: " + runLocally );
        TwitterRollingTrendsTopology twitterRollingTrendsTopology = new TwitterRollingTrendsTopology(topologyName);
        if (runLocally) {
            LOG.info("Running in local mode");
            twitterRollingTrendsTopology.runLocally(topologyName);
        } else {
            LOG.info("Running in remote (cluster) mode");
            twitterRollingTrendsTopology.runRemotely(topologyName);
        }
    }

//    while (true)
//            Utils.sleep(30000);
//        cluster.killTopology("test");
//        cluster.shutdown();
}
