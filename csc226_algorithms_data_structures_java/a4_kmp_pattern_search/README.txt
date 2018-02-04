   Input:
   A text file (the genome) and a pattern (the gene).
   Both consist entirely of characters from the alphabet {A, C, G, T}.
   
   Output:
   If the text contains the pattern, the index of the first occurrence of
   the pattern in the text. Otherwise, the length of the text.

This program is an implementation of the KMP pattern searching algorithm.
It runs in O(N+M).