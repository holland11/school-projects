/* ShortestPaths.java
   CSC 226 - Fall 2017
   
   Implemented by:
   Patrick Holland
      
   This template includes some testing code to help verify the implementation.
   To interactively provide test inputs, run the program with
	java ShortestPaths
	
   To conveniently test the algorithm with a large input, create a text file
   containing one or more test graphs (in the format described below) and run
   the program with
	java ShortestPaths file.txt
   where file.txt is replaced by the name of the text file.
   
   The input consists of a series of graphs in the following format:
   
    <number of vertices>
	<adjacency matrix row 1>
	...
	<adjacency matrix row n>
	
   Entry A[i][j] of the adjacency matrix gives the weight of the edge from 
   vertex i to vertex j (if A[i][j] is 0, then the edge does not exist).
   Note that since the graph is undirected, it is assumed that A[i][j]
   is always equal to A[j][i].
	
   An input file can contain an unlimited number of graphs; each will be 
   processed separately.


   B. Bird - 08/02/2014
*/

import java.io.File;
import java.io.FileNotFoundException;
import java.util.*;


//Do not change the name of the ShortestPaths class
public class ShortestPaths{

    //TODO: Your code here   
    public static int num_v;
	public static int[] distance;
	public static int[] parent;
	/* ShortestPaths(G) 
	   Given an adjacency matrix for graph G, calculates and stores the
	   shortest paths to all the vertices from the source vertex.
		
		If G[i][j] == 0, there is no edge between vertex i and vertex j
		If G[i][j] > 0, there is an edge between vertices i and j, and the
		value of G[i][j] gives the weight of the edge.
		No entries of G will be negative.
	*/
	static void ShortestPaths(int[][] G, int source){
		num_v = G.length;
		int MAX = 2000 * num_v; // maximum edge weight is 1000, so distance will never exceed 1000*|V|
		distance = new int[num_v];
		parent = new int[num_v];
		boolean[] marked = new boolean[num_v];
		for (int i = 0; i < num_v; i++) {
			parent[i] = -1;
			distance[i] = MAX;
			marked[i] = false;
		}
		distance[source] = 0;
		
		Comparator<Vertex> comparator = new DistanceComparator();
		PriorityQueue<Vertex> pq = new PriorityQueue<Vertex>(num_v, comparator);
		for (int i = 0; i < num_v; i++) {
			pq.offer(new Vertex(i,distance[i]));
		}
		while (pq.peek() != null) {
			// this loop will only do work for each vertex once 
			Vertex vert = pq.poll();
			int u = vert.id;
			if (marked[u] == true) {
				// because Java's PriorityQueue doesn't have a updatekey method, we must keep track of which vertices have been finalized
				// so we don't process them multiple times
				continue;
			}
			marked[u] = true;
			for (int i = 0; i < num_v; i++) {
				// this loop will run |V| times each iteration, however work will only be done
				// if there is an edge between V[u] and V[j]
				// each edge has two endpoints so each edge will be processed in this loop twice
				// which results in this loop doing work at most 2*|E| times throughout the algorithm
				if (G[u][i] == 0) {
					continue;
				}
				if ((distance[u] + G[u][i]) < distance[i]) {
					// this is the 'work' that's being done in this loop
					// the first 3 lines are O(1)
					// the pq.offer(v) line is log(pq.size())
					// pq.size() would normally be upper bounded by |V|, however due to Java's PriorityQueue not having an updateKey() method,
					// pq could contain multiple instances of each vertex.
					// at most, pq.size() could be |V|^2 which results in pq.offer(v) being O(log(|V|^2)
					// this is equivalent to O(2*log(|V|) which is equivalent to O(log(|V|))
					// Therefore, this loop runs at most 2*|E| times and does at most log(|V|^2) each iteration
					// which results in O(|E|*log(|V|))
					distance[i] = distance[u] + G[u][i];
					parent[i] = u;
					Vertex v = new Vertex(i,distance[i]);
					pq.offer(v);
				}
			}
		}            
	}
        
	static void PrintPaths(int source){
		/*
		The path from 0 to 0 is: 0 and the total distance is : 0
		The path from 0 to 1 is: 0 --> 7 --> 1 and the total distance is : 35
		The path from 0 to 2 is: 0 --> 2 and the total distance is : 26
		The path from 0 to 3 is: 0 --> 2 --> 3 and the total distance is : 43
		The path from 0 to 4 is: 0 --> 4 and the total distance is : 38
		The path from 0 to 5 is: 0 --> 7 --> 5 and the total distance is : 44
		The path from 0 to 6 is: 0 --> 6 and the total distance is : 57
		The path from 0 to 7 is: 0 --> 7 and the total distance is : 16
		*/
	    for (int i = 0; i < num_v; i++) {
			Stack<Integer> stack = new Stack<Integer>();
			int v = i;
			if (v != source) {
				stack.push(v);
			}
			while (v != source && parent[v] != source) {
			   stack.push(parent[v]);
			   v = parent[v];
			}
			System.out.print("The path from "+source+" to "+i+" is: "+source);
			while (stack.isEmpty() == false) {
			   v = stack.pop();
			   System.out.print(" --> "+v);
			}
			System.out.println(" and the total distance is : "+distance[i]);
	    }
	}
	
	private static class Vertex {
		public int id;
		public int distance;
		
		public Vertex(int id, int distance) {
			this.id = id;
			this.distance = distance;
		}
		public boolean equals(Vertex v) {
			return v.id == id;
		}
	}
	
	private static class DistanceComparator implements Comparator<Vertex>
	{
		public int compare(Vertex v1, Vertex v2)
		{
			// Assume neither string is null. Real code should
			// probably be more robust
			// You could also just return x.length() - y.length(),
			// which would be more efficient.
			if (v1.distance < v2.distance)
			{
				return -1;
			}
			if (v1.distance > v2.distance)
			{
				return 1;
			}
			return 0;
		}
	}
        
		
	/* main()
	   Contains code to test the ShortestPaths function. You may modify the
	   testing code if needed, but nothing in this function will be considered
	   during marking, and the testing process used for marking will not
	   execute any of the code below.
	*/
	public static void main(String[] args) throws FileNotFoundException{
		Scanner s;
		if (args.length > 0){
			try{
				s = new Scanner(new File(args[0]));
			} catch(java.io.FileNotFoundException e){
				System.out.printf("Unable to open %s\n",args[0]);
				return;
			}
			System.out.printf("Reading input values from %s.\n",args[0]);
		}else{
			s = new Scanner(System.in);
			System.out.printf("Reading input values from stdin.\n");
		}
		
		int graphNum = 0;
		double totalTimeSeconds = 0;
		
		//Read graphs until EOF is encountered (or an error occurs)
		while(true){
			graphNum++;
			if(graphNum != 1 && !s.hasNextInt())
				break;
			System.out.printf("Reading graph %d\n",graphNum);
			int n = s.nextInt();
			int[][] G = new int[n][n];
			int valuesRead = 0;
			for (int i = 0; i < n && s.hasNextInt(); i++){
				for (int j = 0; j < n && s.hasNextInt(); j++){
					G[i][j] = s.nextInt();
					valuesRead++;
				}
			}
			if (valuesRead < n*n){
				System.out.printf("Adjacency matrix for graph %d contains too few values.\n",graphNum);
				break;
			}
			long startTime = System.currentTimeMillis();
			
			ShortestPaths(G, 0);
                        PrintPaths(0);
			long endTime = System.currentTimeMillis();
			totalTimeSeconds += (endTime-startTime)/1000.0;
			
			//System.out.printf("Graph %d: Minimum weight of a 0-1 path is %d\n",graphNum,totalWeight);
		}
		graphNum--;
		System.out.printf("Processed %d graph%s.\nAverage Time (seconds): %.2f\n",graphNum,(graphNum != 1)?"s":"",(graphNum>0)?totalTimeSeconds/graphNum:0);
	}
}