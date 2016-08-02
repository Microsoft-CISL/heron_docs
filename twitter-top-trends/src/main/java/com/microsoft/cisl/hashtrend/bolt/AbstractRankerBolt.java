package com.microsoft.cisl.hashtrend.bolt;

import backtype.storm.Config;
import backtype.storm.task.OutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseRichBolt;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Tuple;
import com.microsoft.cisl.hashtrend.window.Rankings;
import org.apache.log4j.Logger;

import java.util.HashMap;
import java.util.Map;

/**
 * @author  Panagiotis Garefalakis
 * @version 1.0
 * Created by pgaref on 8/1/16.
 *
 * This abstract bolt provides the basic behavior of bolts that rank objects according to their count.
 * <p/>
 * It uses a template method design pattern for {@link AbstractRankerBolt#(Tuple, OutputCollector)} to allow
 * actual bolt implementations to specify how incoming tuples are processed, i.e. how the objects embedded within those
 * tuples are retrieved and counted.
 */
public abstract class AbstractRankerBolt extends BaseRichBolt {

    private static final long serialVersionUID = 4931640198501530202L;
    private static final int DEFAULT_EMIT_FREQUENCY_IN_SECONDS = 2;
    private static final int DEFAULT_COUNT = 10;

    private final int emitFrequencyInSeconds;
    protected final Rankings rankings;
    private final int count;
    private OutputCollector collector;
    private long startTime;

    public AbstractRankerBolt() {
        this(DEFAULT_COUNT, DEFAULT_EMIT_FREQUENCY_IN_SECONDS);
    }

    public AbstractRankerBolt(int topN) {
        this(topN, DEFAULT_EMIT_FREQUENCY_IN_SECONDS);
    }

    public AbstractRankerBolt(int topN, int emitFrequencyInSeconds) {
        if (topN < 1) {
            throw new IllegalArgumentException("topN must be >= 1 (you requested " + topN + ")");
        }
        if (emitFrequencyInSeconds < 1) {
            throw new IllegalArgumentException(
                    "The emit frequency must be >= 1 seconds (you requested " + emitFrequencyInSeconds + " seconds)");
        }
        count = topN;
        this.emitFrequencyInSeconds = emitFrequencyInSeconds;
        rankings = new Rankings(count);
    }

    @SuppressWarnings("rawtypes")
    public void prepare(Map stormConf, TopologyContext context, OutputCollector collector) {
        this.collector = collector;
        this.startTime = System.currentTimeMillis();
    }

    protected Rankings getRankings() {
        return rankings;
    }

    /**
     * This method functions as a template method (design pattern).
     */
    public final void execute(Tuple tuple) {
        if ( tuple.getSourceStreamId().equals("__tick") ) {
            getLogger().debug("Received tick tuple, triggering emit of current rankings");
            emitRankings(collector);
        } else {
            updateRankingsWithTuple(tuple);
        }
    }

    abstract void updateRankingsWithTuple(Tuple tuple);

    abstract void emitRankings(OutputCollector collector);

    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("rankings"));
    }

    @Override
    public Map<String, Object> getComponentConfiguration() {
        Map<String, Object> conf = new HashMap<String, Object>();
        conf.put(Config.TOPOLOGY_TICK_TUPLE_FREQ_SECS, emitFrequencyInSeconds);
        return conf;
    }

    abstract Logger getLogger();
}

