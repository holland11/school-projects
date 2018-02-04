/**
 *
 * Patrick Holland
 * September 20, 2017
 * CSC 226 - Fall 2017
 * Assignment 1
 */
 
import java.util.*; 
import java.io.*;

public class QuickSelect {

	private static final int GROUP_SIZE = 7;
       
    public static int QuickSelect(int[] A, int k){
		if (k > A.length) {
			return -1;
		}
		else if (k == A.length) {
			int max = A[0];
			for (int i = 1; i < A.length; i++) {
				if (A[i] > max) {
					max = A[i];
				}
			}
			return max;
		}
		else if (k == 1) {
			int low = A[0];
			for (int i = 1; i < A.length; i++) {
				if (A[i] < low) {
					low = A[i];
				}
			}
			return low;
		}
        return quick_select(A,k,0,A.length-1);
    }
	
	public static int quick_select(int[] A, int k, int start, int end) {
		// start by finding median of medians to be pivot
		// split array into n/7 groups of 7
		// sort those groups
		// median will be in position 4 of each group
		// move each median to the 'front' of the array
		// run quick_select on the portion of the array representing medians
		if (start == end) {
			return A[start];
		}
		int num_elements = end-start+1;
		int num_groups = (int)Math.ceil((float)num_elements / GROUP_SIZE);
		int[][] A_groups = new int[num_groups][3]; // A_groups[i][0] = start index, [i][1] = end index, [i][2] = median index
		for (int i = 0; i < num_groups; i++) {
			A_groups[i][0] = start + (GROUP_SIZE*i);
			A_groups[i][1] = A_groups[i][0] + GROUP_SIZE - 1;
			if (A_groups[i][1] > end) {
				A_groups[i][1] = end;
			}
		}

		find_and_move_medians(A,A_groups);

		//int pivot = quick_select(A,((end-start+1)/2)+1,start,num_groups);
		int pivot = A[start];
		for (int i = 0; i < num_groups; i++) {
			if (A[start+i] == pivot) {
				swap(A,start,start+i);
				break;
			}
		}
		
		int pivot_index = partition(A,pivot,start,end);
		if (pivot_index == -1 && start != end) {
			System.err.println("pivot_index returning -1 with more than 1 element in 'slice'");
			System.exit(-1);
			return 0;
		}
		else if (pivot_index+1 == k) {
			return pivot;
		}
		else if (pivot_index+1 > k) {
			return quick_select(A,k,start,pivot_index-1);
		}
		else {
			return quick_select(A,k,pivot_index+1, end);
		}
	}
	
	public static int partition(int[] A, int pivot, int start, int end) {
		// return the index of the pivot at the end of all swaps
		/*
		A = [26,7,3,55,24,29,4,26,83,0]
		i = start+1 = 1
		j = end = 9
		while (i <= j) {
			// [26,7,3,0,24,29,4,26,83,55]
			// [26,7,3,0,24,26,4,29,83,55]
			// [4,7,3,0,24,26,26,29,83,55]
			while (A[i] <= pivot) {
				i++;
			}
			while (A[j] > pivot) {
				j--;
			}
			if (i > j) {
				swap(A,0,j); // swap pivot with last low number
				pivot_index = j;
				return pivot_index;
			}
			else {
				swap(A,i,j); // swap A[i] with A[j]
			}
		*/
		int i = start+1;
		int j = end;
		while (i <= j) {
			while (A[i] <= pivot) {
				i++;
			}
			while (A[j] > pivot) {
				j--;
			}
			if (i > j) {
				swap(A,start,j);
				return j;
			}
			else {
				swap(A,i,j);
			}
		}
		return -1;
	}
	
	public static void find_and_move_medians(int[] A, int[][] A_groups) {
		int median_offset = (GROUP_SIZE / 2);
		for (int i = 0, n = A_groups.length; i < n; i++) {
			Arrays.sort(A,A_groups[i][0],A_groups[i][1]+1);
			if (i == n-1) {
				median_offset = ((A_groups[i][1] - A_groups[i][0] + 1) / 2);
			}
			A_groups[i][2] = A_groups[i][0] + median_offset;
		}
		for (int i = 0, n = A_groups.length; i < n; i++) {
			swap(A,A_groups[0][0]+i,A_groups[i][2]);
		}
	}
	
	public static void swap(int[] A, int i, int j) {
		int temp = A[i];
		A[i] = A[j];
		A[j] = temp;
		return;
	}
	
	public static void printList(int[] A) {
		System.out.print("[");
		for (int i = 0; i < A.length; i++) {
			System.out.print(A[i]);
			if (i != A.length-1) {
				System.out.print(",");
			}
		}
		System.out.println("]");
	}
	
	public static void printList(int[][] A) {
		System.out.print("[");
		for (int i = 0; i < A.length; i++) {
			System.out.print("[");
			for (int j = 0; j < A[i].length; j++) {
				System.out.print(A[i][j]);
				if (j != A[i].length-1) {
					System.out.print(",");
				}
			}
			System.out.print("]");
			if (i != A.length-1) {
				System.out.print(",");
			}
		}
		System.out.println("]");
	}
    
    public static void main(String[] args) {
		int size = 4500000;
		int k_size = 5;
		int max = 4400000;
		int k_max = size;
		Random r = new Random();
		int[] ks = new int[k_size];
		int[] A = new int[size];
		for (int i = 0; i < size; i++) {
			A[i] = r.nextInt(max);
		}
		for (int i = 0; i < k_size; i++) {
			ks[i] = r.nextInt(k_max);
		}
		int[] A_sorted = new int[A.length];
		for (int i = 0; i < A.length; i++) {
			A_sorted[i] = A[i];
		}
		long time1 = System.currentTimeMillis();
		Arrays.sort(A_sorted);
		long time2 = System.currentTimeMillis();
		System.out.println("Time to sort: "+ (time2-time1) +"ms");
		for (int i = 0; i < ks.length; i++) {
			time1 = System.currentTimeMillis();
			System.out.println("QuickSelect says " + QuickSelect(A, ks[i]));
			if (ks[i] >= A.length) {
				System.out.println("The answer is -1.");
				continue;
			}
			else {
				System.out.println("The answer is " + A_sorted[ks[i]-1]);
			}
			time2 = System.currentTimeMillis();
			System.out.println("Time to quickselect: "+ (time2-time1) +"ms");
		}
		System.out.println("The size of the array is: " +A.length);
    }
    
}

/* 
example (smaller scale so using n/3 as number of groups)
quickselect(A,0,A.length,5)
A = [7,26,3,55,24,29,4,26,83,0]
A_sorted = [0,3,4,7,24,26,26,29,55,83]
A1 = [7,26,3] A2 = [55,24,29] A3 =[4,26,83] A4 = [0]
A1 = [0,2] A2 = [3,5] A3 = [6,8] A4 = [9,9]
A_indeces[(n/3)+1][2] ^^

A1[0][2] = 0 A1[1][2] = 5 [2][2] = 7 [3][2] = 9
swap those to the front of the array
// run quickselect on the portion of the array only containing group medians
int pivot = quickselect(A,start,(n/3)+1); start/end index parameters
pivot = 26 (higher of middle two when even number n)
swap pivot to front
int pivot_index = partition(A,start,end,pivot)
	A = [26,7,3,55,24,29,4,26,83,0]
	i = start+1 = 1
	j = end = 9
	while (i <= j) {
		// [26,7,3,0,24,29,4,26,83,55]
		// [26,7,3,0,24,26,4,29,83,55]
		// [4,7,3,0,24,26,26,29,83,55]
		while (A[i] <= pivot) {
			i++;
		}
		while (A[j] > pivot) {
			j--;
		}
		if (i > j) {
			swap(A,0,j); // swap pivot with last low number
			pivot_index = j;
			return pivot_index;
		}
		else {
			swap(A,i,j); // swap A[i] with A[j]
		}
	}
// pivot_index = 6
// k = 5 || k-1 = 4
if (pivot_index == k-1) {
	return pivot;
}
else if (pivot_index > k-1) {
	// [4,7,3,0,24,26,26,29,83,55]
	return quickselect(A,start,pivot_index-1);
	// [4,7,3,0,24,26]
	// [4,7,3],[0,24,26]
	// [3,4,7],[0,24,26]
	// [4,24,7,0,3,26]
	// pivot = 24
	// [24,4,7,0,3,26]
	// i = 1, j = 5
	// [3,4,7,0,24,26]
	// pivot_index == 4, k-1= 4
	// return A[4] = 24
}
else {
	return quickselect(A,pivot_index+1,end);
}


*/