package com.timestored.kdb.examples.feedhandler;

import java.io.IOException;

import kx.c.KException;

/**
 * Demonstrate creating feedhandler, making it listen to incoming data
 * and forwarding to the KDB server.
 * 
 * Before running start a fresh KDB server on port 5000 and enter the below:
 * trade:([]time:`time$();sym:`symbol$();price:`float$();size:`int$();stop:`boolean$();cond:`char$();ex:`char$())
 * .u.upd:insert
 * This allows using the same commands as a KDB+ tickerplant.
 */
public class FeedDemo {
	public static void main(String... args) throws KException, IOException {
		FeedHandler feedHandler = new FeedHandler("localhost", 5001);
		FakeFeed.INSTANCE.addListener(feedHandler);
	}
}
