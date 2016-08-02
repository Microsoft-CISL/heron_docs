package com.microsoft.cisl.hashtrend.window;

/**
 * @author  Panagiotis Garefalakis
 * @version 1.0
 * Created by pgaref on 8/1/16.
 */
public interface Rankable  extends Comparable<Rankable>{

    Object getObject();

    long getCount();

    /**
     * Note: We do not defensively copy the object wrapped by the Rankable.  It is passed as is.
     *
     * @return a defensive copy
     */
    Rankable copy();

}
