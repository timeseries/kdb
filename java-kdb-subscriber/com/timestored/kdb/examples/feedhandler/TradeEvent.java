package com.timestored.kdb.examples.feedhandler;

import java.sql.Time;

/**
 * Contains data for a single trade.
 */
public class TradeEvent {
	
	public final Time time;
	public final String sym;
	public final double price;
	public final int size;
	public final boolean stop;
	public final char cond;
	public final char ex;
	
	public TradeEvent(Time time, String sym, double price, int size, 
			boolean stop, char cond, char ex) {
		super();
		this.time = time;
		this.sym = sym;
		this.price = price;
		this.size = size;
		this.stop = stop;
		this.cond = cond;
		this.ex = ex;
	}
}