package com.timestored.kdb.examples.feedhandler;

import java.util.List;

/**
 * Allows listening to incoming trade data.
 */
public interface FeedListener {
	
	/**
	 * Event received when a number of trades have occurred.
	 */
	public void tradeEvent(List<TradeEvent> trades);
}
