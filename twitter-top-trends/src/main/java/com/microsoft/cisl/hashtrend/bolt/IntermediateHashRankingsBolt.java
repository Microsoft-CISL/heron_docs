package com.microsoft.cisl.hashtrend.bolt;

import backtype.storm.task.OutputCollector;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Values;
import com.microsoft.cisl.hashtrend.window.Rankable;
import com.microsoft.cisl.hashtrend.window.RankableObjectWithFields;
import org.apache.log4j.Logger;

/**
 * @author  Panagiotis Garefalakis
 * @version 1.0
 * Created by pgaref on 8/1/16.
 *
 * This bolt ranks incoming objects by their count.
 * <p/>
 * It assumes the input tuples to adhere to the following format: (object, object_count, additionalField1,
 * additionalField2, ..., additionalFieldN).
 */
public final class IntermediateHashRankingsBolt extends AbstractRankerBolt {

    private static final long serialVersionUID = -1369800530256637409L;
    private static final Logger LOG = Logger.getLogger(IntermediateHashRankingsBolt.class);

    public IntermediateHashRankingsBolt() {
        super();
    }

    public IntermediateHashRankingsBolt(int topN) {
        super(topN);
    }

    public IntermediateHashRankingsBolt(int topN, int emitFrequencyInSeconds) {
        super(topN, emitFrequencyInSeconds);
    }

    @Override
    void updateRankingsWithTuple(Tuple tuple) {
        Rankable rankable = RankableObjectWithFields.from(tuple);
        super.getRankings().updateWith(rankable);
    }

    @Override
    void emitRankings(OutputCollector collector) {
        System.out.println("Intermediate Rankings: " + rankings.getRankings());
        if(rankings.getRankings().size()>0)
            collector.emit(new Values(rankings));
    }

    @Override
    Logger getLogger() {
        return LOG;
    }

}



