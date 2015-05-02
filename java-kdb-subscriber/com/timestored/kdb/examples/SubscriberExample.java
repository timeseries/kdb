package com.timestored.kdb.examples;

import java.io.IOException;

import kx.c;
import kx.c.KException;

/**
 * Subscribe to all syms  on the trade table for a selected host / port.
 */
public class SubscriberExample {
	
	public SubscriberExample(final String host, final int port) {
		try {
			c con = new c(host, port);
			con.k(".u.sub[`trade;`]"); 
			
			while (true) {
				try {
					Object r = con.k();
					if (r != null) {
						Object[] data = (Object[]) r;

						String tblname = (data[1]).toString();
						c.Flip tbl = (c.Flip) data[2];
						String[] colNames = tbl.x;
						Object[] colData = tbl.y;
						
						String s = tblname + " update. row 1/" + colData.length + " ->";
						for (int i = 0; i < colData.length; i++) {
							s += " " + colNames[i] + ":" + c.at(colData[i], 0).toString();
						}
						System.out.println(s);
					}
				} catch (Exception e) {
					System.err.println(e.toString());
				}
			}
			
		} catch (KException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}
	
	public static void main(String[] args) {
		if(args.length != 2) {
			System.err.println("You must call with args: SubscriberExample {hostname} {port}");
		} else {
			new SubscriberExample(args[0], Integer.parseInt(args[1]));	
		}
	}
}
