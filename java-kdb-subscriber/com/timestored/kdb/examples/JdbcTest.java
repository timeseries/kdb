package com.timestored.kdb.examples;

// q -p 5001 use q/c/jdbc.jar
import java.sql.*;

public class JdbcTest {

	public static void main(String args[]) {
		try {
			Class.forName("jdbc");
			// loads the driver
			Connection h = DriverManager.getConnection("jdbc:q:localhost:5001", "", "");
			Statement e = h.createStatement();

			e.executeUpdate("create table t(x int,f float,s varchar(0),d date,t time,z timestamp)");
			e.execute("insert into t values(9,2.3,'aaa',date'2000-01-02',time'12:34:56',timestamp'2000-01-02 12:34:56)");


			ResultSet r = e.executeQuery("select * from t");
			ResultSetMetaData m = r.getMetaData();
			int n = m.getColumnCount();
			for (int i = 0; i < n;)
				System.out.println(m.getColumnName(++i));
			while (r.next())
				for (int i = 0; i < n;)
					System.out.println(r.getObject(++i));

			h.close();
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}

	}
}
