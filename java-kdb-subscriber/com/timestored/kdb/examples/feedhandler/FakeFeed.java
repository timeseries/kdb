package com.timestored.kdb.examples.feedhandler;

import java.sql.Time;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.concurrent.CopyOnWriteArrayList;


/**
 * Fakes a market data feed. Listeners may be added to receive {@link TradeEvent}'s.
 */
public enum FakeFeed {
	INSTANCE;

	private static final Random R = new Random();

	private static final String[] SYMS = new String[] { "GOOG", "A", "GM", "KX" };
	private static final char[] CONDS = new char[] { 'B', 'S' };
	private static final char[] EXS = new char[] { 'L', 'N' };
	private static final double MAX_PRICE = 100.0;
	private static final int MAX_RECORDS = 10;
	private static final int MAX_SIZE = 1000;

	private final CopyOnWriteArrayList<FeedListener> listeners
		= new CopyOnWriteArrayList<FeedListener>();

	
	private FakeFeed() {
		Runnable r = new Runnable() {

			@Override
			public void run() {

				while(true) {
					int numRecords = 1 + R.nextInt(MAX_RECORDS);
					ArrayList<TradeEvent> trades = new ArrayList<TradeEvent>(numRecords);
	
					for(int i=0; i<numRecords; i++) {
						TradeEvent te = new TradeEvent(new Time(System.currentTimeMillis()), 
								SYMS[R.nextInt(SYMS.length)], 
								R.nextDouble() * MAX_PRICE, 
								R.nextInt(MAX_SIZE), 
								R.nextBoolean(), 
								CONDS[R.nextInt(CONDS.length)], 
								EXS[R.nextInt(EXS.length)]);
						trades.add(te);
					}
					
					List<TradeEvent> t = Collections.unmodifiableList(trades);
					for(FeedListener fl : listeners) {
						fl.tradeEvent(t);
					}
					try {
						Thread.sleep(500);
					} catch (InterruptedException e) {
						// ignore
					}
				}
			}
		};
		new Thread(r).start();
	}
	
	public void addListener(FeedListener feedListener) {
		listeners.add(feedListener);
	}
	
	public void removeListener(FeedListener feedListener) {
		listeners.remove(feedListener);
	}
}
