/* 

   CSC 226 Assignment 4
   Fall 2017
   Patrick Holland
   
   Input:
   A text file (the genome) and a pattern (the gene).
   Both consist entirely of characters from the alphabet {A, C, G, T}.
   
   Output:
   If the text contains the pattern, the index of the first occurrence of
   the pattern in the text. Otherwise, the length of the text.
*/

import java.util.Scanner;
import java.io.File;
import java.io.FileNotFoundException;


public class  KMP 
{
    private static String pattern;
	private static int[][] dfa;
	private static char[] alphabet = {'A', 'C', 'G', 'T'};
   
    public KMP(String pattern){
		this.pattern = pattern;
		dfa = new int[alphabet.length][pattern.length()];
		int index = retrieve_index(alphabet, pattern.charAt(0));
		if (index == -1) {
			System.out.println("First character of the pattern is not a valid character in the alphabet. Exiting.");
			System.exit(-1);
		}
		dfa[index][0] = 1; // s0 -> s1 requires pattern[0]
		/*
			pattern: "ababc"
			text: "abababc"
			
		*/
		for (int i = 1, trail = 0; i < pattern.length(); i++) {
			index = retrieve_index(alphabet, pattern.charAt(i));
			if (index < 0) {
				System.out.println("Character in index "+i+" ("+pattern.charAt(i)+") of pattern is not in the alphabet. Exiting.");
				System.exit(-1);
			}
			for (int k = 0; k < alphabet.length; k++) {
				dfa[k][i] = dfa[k][trail];
			}
			dfa[index][i] = i+1;
			trail = dfa[index][trail];
		}
    }
	
	private static Integer retrieve_index(char[] alphabet, char charmander) {
		for (int i = 0; i < alphabet.length; i++) {
			if (alphabet[i] == charmander) {
				return i;
			}
		}
		return -1;
	}
    
    public static int search(String txt){  
		int dfa_index = 0;
		for (int i = 0, n = txt.length(); i < n; i++) {
			int index = retrieve_index(alphabet,txt.charAt(i));
			if (index == -1) {
				System.out.println("Character at index "+i+" ("+txt.charAt(i)+") of text is not in the alphabet. Ignoring it.");
				continue;
			}
			dfa_index = dfa[index][dfa_index];
			if (dfa_index >= dfa[0].length) {
				return i-pattern.length()+1;
			}
		}
		return txt.length()+1;
    }
    
    
    public static void main(String[] args) throws FileNotFoundException{
	Scanner s;
	if (args.length > 0){
	    try{
		s = new Scanner(new File(args[0]));
	    } catch(java.io.FileNotFoundException e){
		System.out.println("Unable to open "+args[0]+ ".");
		return;
	    }
	    System.out.println("Opened file "+args[0] + ".");
	    String text = "";
	    while(s.hasNext()){
		text += s.next() + " ";
	    }
	    
	    for(int i = 1; i < args.length; i++){
		KMP k = new KMP(args[i]);
		int index = search(text);
		if(index >= text.length())System.out.println(args[i] + " was not found.");
		else System.out.println("The string \"" + args[i] + "\" was found at index " + index + ".");
	    }
	    
	    //System.out.println(text);
	    
	}
	else{
	    System.out.println("usage: java SubstringSearch <filename> <pattern_1> <pattern_2> ... <pattern_n>.");
	}
	
	
    }
}
