/* MST.java
   CSC 226 - Fall 2018
   Problem Set 2 - Template for Minimum Spanning Tree algorithm
   
   Implemented by
   Patrick Holland
   
   The assignment is to implement the mst() method below, using Kruskal's algorithm
   equipped with the Weighted Quick-Union version of Union-Find. The mst() method computes
   a minimum spanning tree of the provided graph and returns the total weight
   of the tree. To receive full marks, the implementation must run in time O(m log n)
   on a graph with n vertices and m edges.
   
   This template includes some testing code to help verify the implementation.
   Input graphs can be provided with standard input or read from a file.
   
   To provide test inputs with standard input, run the program with
       java MST
   To terminate the input, use Ctrl-D (which signals EOF).
   
   To read test inputs from a file (e.g. graphs.txt), run the program with
       java MST graphs.txt
   
   The input format for both methods is the same. Input consists
   of a series of graphs in the following format:
   
       <number of vertices>
       <adjacency matrix row 1>
       ...
       <adjacency matrix row n>
   	
   For example, a path on 3 vertices where one edge has weight 1 and the other
   edge has weight 2 would be represented by the following
   
   3
   0 1 0
   1 0 2
   0 2 0
   	
   An input file can contain an unlimited number of graphs; each will be processed separately.
   
   (originally from B. Bird - 03/11/2012)
   (tweaked by N. Mehta - 10/3/2017)
*/

import java.util.*;
import java.io.File;

public class MST {


    /* mst(G)
       Given an adjacency matrix for graph G, return the total weight
       of all edges in a minimum spanning tree.
		
       If G[i][j] == 0, there is no edge between vertex i and vertex j
       If G[i][j] > 0, there is an edge between vertices i and j, and the
       value of G[i][j] gives the weight of the edge.
       No entries of G will be negative.
    */
    static int mst(int[][] G) {
		int numVerts = G.length;
		int components = numVerts;
		int totalWeight = 0;

		Comparator<Edge> comparator = new EdgeWeightComparator();
		PriorityQueue<Edge> pq = new PriorityQueue<Edge>(numVerts*numVerts, comparator); // methods: add(), poll() (this is the dequeue/pop/remove method), 
		
		for (int i = 0; i < numVerts; i++) {
			for (int j = i+1; j < numVerts; j++) {
				// j starts at i+1 to avoid looking at edges that we've already seen & avoid looking at edge (j,j)
				if (G[i][j] > 0) {
					Edge e = new Edge(i,j,G[i][j]);
					pq.add(e);
				}
			}
		}
		
		int[] parent_id = new int[numVerts];
		int[] tree_sizes = new int[numVerts];
		for (int i = 0; i < numVerts; i++) {
			parent_id[i] = i;
			tree_sizes[i] = 1;
		}
		
		Edge e = null;
		//printArrays(tree_sizes,parent_id);
		while ((components > 1) && ((e = pq.poll()) != null)) {
			//System.out.println(e);
			if (connected(e.v1,e.v2,parent_id) == false) {
				union(e.v1,e.v2,parent_id,tree_sizes);
				components -= 1;
				totalWeight += e.weight;
			}
			//printArrays(tree_sizes,parent_id);
		}
		
		if (components != 1) {
			System.out.println("Invalid graph. Alg should finish with 1 component, but there are " + components);
		}
			
		return totalWeight;
	}
	
	private static void printArrays(int[] tree_sizes, int[] parent_id) {
		System.out.print("[");
		for (int i = 0, n = tree_sizes.length; i < n; i++) {
			System.out.print(tree_sizes[i]);
			if (i+1 < n) {
				System.out.print(",");
			}
		}
		System.out.println("]");
		System.out.print("[");
		for (int i = 0, n = parent_id.length; i < n; i++) {
			System.out.print(parent_id[i]);
			if (i+1 < n) {
				System.out.print(",");
			}
		}
		System.out.println("]");
	}
	
	private static void union(int v1, int v2, int[] parent_id, int[] tree_sizes) {
		// path compression in find() guarantees that parent_id[v1] and parent_id[v2] are also their 'true roots'
		// so we don't need to traverse through parent_id to find each root
		int r1 = parent_id[v1];
		int r2 = parent_id[v2];
		if (tree_sizes[r1] > tree_sizes[r2]) {
			parent_id[r2] = r1;
			tree_sizes[r1] += tree_sizes[r2];
		}
		else {
			parent_id[r1] = r2;
			tree_sizes[r2] += tree_sizes[r1];
		}
	}
	
	private static boolean connected(int v1, int v2, int[] parent_id) {
		int v1_root = find(v1,parent_id);
		int v2_root = find(v2,parent_id);
		return v1_root == v2_root;
	}
	
	private static int find(int vertex, int[] parent_id) {
		/*
		returns the root node of the vertex
		all vertices which are encountered along the path to the root will be stored 
		once the root is found, all stored vertices will have their parent changed to the root to reduce the length of any path
		*/
		int count = 0;
		ArrayList<Integer> to_compress = new ArrayList<Integer>();
		while (parent_id[vertex] != vertex) {
			// traverse the path until the root is found (storing all vertices along the way)
			to_compress.add(vertex);
			vertex = parent_id[vertex];
		}
		for (int i = 0, n = to_compress.size()-1; i < n; i++) {
			// n = to_compress.size()-1 bcz the last element in to_compress will already have the root as its parent
			parent_id[to_compress.get(i)] = vertex;
		}
		return vertex;
	}
	
	private static class Edge {
		public int v1;
		public int v2;
		public int weight;
		public Edge(int v1, int v2, int weight) {
			this.v1 = v1;
			this.v2 = v2;
			this.weight = weight;
		}
		public String toString() {
			return "("+v1+","+v2+"):"+weight;
		}
	}
	
	private static class EdgeWeightComparator implements Comparator<Edge>
	{
		public int compare(Edge e1, Edge e2)
		{
			// Assume neither string is null. Real code should
			// probably be more robust
			// You could also just return x.length() - y.length(),
			// which would be more efficient.
			if (e1.weight < e2.weight)
			{
				return -1;
			}
			if (e1.weight > e2.weight)
			{
				return 1;
			}
			return 0;
		}
	}


    public static void main(String[] args) {
		/* Code to test your implementation */
		/* You may modify this, but nothing in this function will be marked */

		int graphNum = 0;
		Scanner s;

		if (args.length > 0) {
			//If a file argument was provided on the command line, read from the file
			try {
			s = new Scanner(new File(args[0]));
			}
			catch(java.io.FileNotFoundException e) {
			System.out.printf("Unable to open %s\n",args[0]);
			return;
			}
			System.out.printf("Reading input values from %s.\n",args[0]);
		}
		else {
			//Otherwise, read from standard input
			s = new Scanner(System.in);
			System.out.printf("Reading input values from stdin.\n");
		}
			
		//Read graphs until EOF is encountered (or an error occurs)
		while(true) {
			graphNum++;
			if(!s.hasNextInt()) {
			break;
			}
			System.out.printf("Reading graph %d\n",graphNum);
			int n = s.nextInt();
			int[][] G = new int[n][n];
			int valuesRead = 0;
			for (int i = 0; i < n && s.hasNextInt(); i++) {
			G[i] = new int[n];
			for (int j = 0; j < n && s.hasNextInt(); j++) {
				G[i][j] = s.nextInt();
				valuesRead++;
			}
			}
			if (valuesRead < n * n) {
			System.out.printf("Adjacency matrix for graph %d contains too few values.\n",graphNum);
			break;
			}
			if (!isConnected(G)) {
			System.out.printf("Graph %d is not connected (no spanning trees exist...)\n",graphNum);
			continue;
			}
			int totalWeight = mst(G);
			System.out.printf("Graph %d: Total weight of MST is %d\n",graphNum,totalWeight);
					
		}
	}

		/* isConnectedDFS(G, covered, v)
		   Used by the isConnected function below.
		   You may modify this, but nothing in this function will be marked.
		*/
	static void isConnectedDFS(int[][] G, boolean[] covered, int v) {
		covered[v] = true;
		for (int i = 0; i < G.length; i++) {
			if (G[v][i] > 0 && !covered[i]) {
			isConnectedDFS(G,covered,i);
			}
		}
		}
		   
		/* isConnected(G)
		   Test whether G is connected.
		   You may modify this, but nothing in this function will be marked.
		*/
		static boolean isConnected(int[][] G) {
		boolean[] covered = new boolean[G.length];
		for (int i = 0; i < covered.length; i++) {
			covered[i] = false;
		}
		isConnectedDFS(G,covered,0);
		for (int i = 0; i < covered.length; i++) {
			if (!covered[i]) {
			return false;
			}
		}
		return true;
	}
    
}