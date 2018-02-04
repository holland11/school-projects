#include "linkedlist.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

pval_t* insert_val(pval_t* head, int val, char* command) {
	if (head == NULL) {
		head = new_pval(val, command);
		return head;
	}
	pval_t* node = head;
	while (node->next != NULL) {
		node = node->next;
	}
	node->next = new_pval(val, command);
	return head;
}

pval_t* new_pval(int val, char* command) {
	pval_t* p;
	p = malloc(sizeof(pval_t));
	if (p == NULL) {
		printf("allocation error making new linkedlist node\n");
		exit(6);
	}
	p->val = val;
	strncpy(p->command, command, 1023);
	return p;
}

pval_t* remove_val(pval_t* head, int val) {
	pval_t* temp;
	if (head == NULL) {
		printf("pval couldn't be removed because linked list is empty\n");
		return head;
	}
	else if (head->val == val) {
		temp = head;
		head = head->next;
		free(temp);
		return head;
	}
	pval_t* prev = head;
	pval_t* node = head->next;
	while (node != NULL) {
		if (node->val == val) {
			prev->next = node->next;
			free(node);
			return head;
		}
		prev = node;
		node = node->next;
	}
	printf("pval to be removed could not be found in linked list\n");
	return head;
}

void print_list(pval_t* head) {
	int count = 0;
	while (head != NULL) {
		printf("%d: %s\n", head->val, head->command);
		head = head->next;
		count++;
	}
	printf("Total background jobs: %d\n", count);
	return;
}