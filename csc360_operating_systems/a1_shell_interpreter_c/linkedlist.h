#ifndef _LINKEDLIST_H_
#define _LINKEDLIST_H_

typedef struct pval pval_t;
struct pval { 
    int val;
	char command[1024];
    pval_t *next;
};

pval_t* new_pval(int val, char* command);
pval_t* insert_val(pval_t* head, int val, char* command);
pval_t* remove_val(pval_t* head, int val);
void print_list(pval_t* head);

#endif
