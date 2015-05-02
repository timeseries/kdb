package com.timestored.kdb.examples.feedhandler;

import java.io.IOException;
import java.sql.Time;
import java.util.List;


import kx.c;
import kx.c.KException;

/**
 * Implements {@link FeedListener} so can listen to feeds which it will then
 * parse to a K object and forward to a KDB server.
 */
public class FeedHandler implements FeedListener {

	private static final String[] COL_NAMES 
		= new String[] { "time", "sym", "price", "size", "stop", "cond", "ex" };
	
	private c conn;
	
	public FeedHandler(String host, int port) throws KException, IOException {
		conn = new c(host, port);
	}

	@Override
	public void tradeEvent(List<TradeEvent> trades) {

		int numRecords = trades.size();
		System.out.print("Received " + numRecords + " records from fakefeed. ");
		
		// create the vectors for each column
		Time[] t = new Time[numRecords];
		String[] sym = new String[numRecords];
		double[] price = new double[numRecords];
		int[] size = new int[numRecords];
		boolean[] stop = new boolean[numRecords];
		char[] cond = new char[numRecords];
		char[] ex = new char[numRecords];
		
		// loop through filling the columns with data
		for(int i=0; i<trades.size(); i++) {
			TradeEvent te = trades.get(i);
			t[i] = te.time;
			sym[i] = te.sym;
			price[i] = te.price;
			size[i] = te.size;
			stop[i] = te.stop;
			cond[i] = te.cond;
			ex[i] = te.ex;
		}
		
		// create the table itself from the separate columns
		Object[] data = new Object[] { t, sym, price, size, stop, cond, ex };
		c.Flip tab = new c.Flip(new c.Dict(COL_NAMES, data));
		// create the command to insert the table of data into the named table.
		Object[] updStatement = new Object[] { ".u.upd", "trade", tab };
		try {
			conn.ks(updStatement); // send asynchronously
			System.out.println("Sent " + numRecords + " records to KDB server");
		} catch (IOException e) {
			System.err.println("error sending feed to server.");
		}
	}
	
}
