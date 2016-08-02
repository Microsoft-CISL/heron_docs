package com.microsoft.cisl.hashtrend.spout;

import backtype.storm.spout.SpoutOutputCollector;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.base.BaseRichSpout;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Values;
import backtype.storm.utils.Utils;
import twitter4j.*;

import java.util.Map;
import java.util.concurrent.*;

/**
 * @author  Panagiotis Garefalakis
 * @version 1.0
 *
 * Created by pgaref on 31/07/16.
 */
public class TweetStreamSpout extends BaseRichSpout {

    private static final long serialVersionUID = -3217886193225455451L;

    private BlockingQueue<String> HashTagsQueue;
    private TwitterStream twitterStream;
    private SpoutOutputCollector collector;
    private long nItems;
    private long startTime;

    /**
     * Configurable variables
     */

    public void open(Map<String, Object> map, TopologyContext topologyContext, SpoutOutputCollector spoutOutputCollector) {

        nItems = 0;
        startTime = System.currentTimeMillis();
        collector = spoutOutputCollector;

        //Open the stream
        this.twitterStream = new TwitterStreamFactory().getInstance();
        // Create an appropriately sized blocking queue
        HashTagsQueue = new LinkedBlockingQueue<String>(100000);

        //Create a listener for tweets (Status)
        final StatusListener listener = new StatusListener() {

            //If there's a tweet, add to the queue
            public void onStatus(Status status) {
                ++nItems;
                printStats();
                //Get the tweet and Loop through the hashtags
                for (HashtagEntity hashtag : status.getHashtagEntities()) {
                    HashTagsQueue.offer(hashtag.getText());
                }
            }
            //Everything else is empty because we only care about the status (tweet)
            public void onDeletionNotice(StatusDeletionNotice sdn) { }

            public void onTrackLimitationNotice(int i) { }

            public void onScrubGeo(long l, long l1) { }

            public void onException(Exception e) { }

            public void onStallWarning(StallWarning warning) { }
        };

        //Add the listener to the stream
        twitterStream.addListener(listener);
        twitterStream.sample();
    }

    public void close() { this.twitterStream.shutdown(); }

    public void nextTuple() {
        String msg = HashTagsQueue.poll();
        while (msg == null) {
            Utils.sleep(100);
            msg = HashTagsQueue.poll();
        }
        collector.emit(new Values(msg));
    }

    public void ack(Object msgId) { }

    public void fail(Object msgId) { }


    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("tweet"));
    }

    public void printStats(){
        if(System.currentTimeMillis() - startTime > 10000){
            System.out.println( "Streaming: "+ nItems/10 + " - Tweets per Second -> Pending Tags: "+ this.HashTagsQueue.size());
            startTime = System.currentTimeMillis();
            nItems = 0;
        }
    }

}
