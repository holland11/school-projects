/*

Patrick Holland
University of Victoria - CSC 360 Assignment 1
Winter 2018

This assignment is to create a simple shell interpreter for linux (SSI).
I read https://brennan.io/2015/01/16/write-a-shell-in-c/ which helped me understand the concepts involved.

For command "cd", I allow for spaces in the pathname. If there are spaces (aka multiple parameters) they are treated all as one path.
For example in bash you would type (cd "../my directory"), but in my SSI you type (cd ../my directory).

*/


#include <stdio.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <stdlib.h>
#include "linkedlist.h"
#include <signal.h>

char* get_working_directory();
char** tokenize(char* input);
char* replace_tilda_w_home(char* path, char* home_path);
void handle_cd(char** tokens, char* reply_backup);
pval_t* handle_bg(char** tokens, pval_t* bg_head, char* reply_backup);
void handle_bglist(pval_t* bg_head);
pval_t* handle_bg_check(pval_t* bg_head);
void handle_other(char** tokens);


int main()
{
	const char* prompt_start = "SSI: ";
	const char* prompt_end = "> ";
	pval_t* bg_head = NULL;

	int bailout = 0;
	while (!bailout) {
		printf("%s",prompt_start);
		char* working_directory = get_working_directory();
		printf("%s ",working_directory);
		
		char* reply = readline(prompt_end);
		if (!strcmp(reply, "")) { // empty line will give seg faults if not checked for
			bg_head = handle_bg_check(bg_head);
			free(reply);
			continue;
		}
		if (reply[0] == ' ') { // line with only spaces will give seg faults so not going to allow any line to start with a space.
			printf("shell commands cannot begin with whitespace\n");
			bg_head = handle_bg_check(bg_head);
			free(reply);
			continue;
		}
		char* reply_backup = malloc(strlen(reply)+1);
		if (reply_backup == NULL) {
			printf("allocation error on malloc\n");
			exit(5);
		}
		strcpy(reply_backup, reply);
		char** tokens = tokenize(reply);
		
		if (!strcmp(reply, "bye") || !strcmp(reply, "exit")) {
			bailout = 1;
		} 
		else {
			if (!strcmp(tokens[0], "cd")) {
				handle_cd(tokens, reply_backup);
			}
			else if (!strcmp(tokens[0], "bg")) {
				bg_head = handle_bg(tokens, bg_head, reply_backup);
			}
			else if (!strcmp(tokens[0], "bglist")) {
				handle_bglist(bg_head);
			}
			else {
				handle_other(tokens);
			}
		}
		
		bg_head = handle_bg_check(bg_head);
	
		free(tokens);
		free(reply);
		free(working_directory);
	}
	printf("Bye Bye\n");
}

void handle_cd(char** tokens, char* reply_backup) {
	if (tokens[1] == NULL) {
		if (chdir(getenv("HOME")) != 0) {
			printf("chdir error getting home path\n");
		}
	}
	else {
		char* path = replace_tilda_w_home((reply_backup+3), getenv("HOME"));
		printf("path name: %s\n", path);
		if (chdir(path) != 0) {
			printf("chdir error\n");
		}
		free(path);
	}
}

pval_t* handle_bg(char** tokens, pval_t* bg_head, char* reply_backup) {
	pid_t p = fork();
	if (p == 0) { // child
		execvp(tokens[1], (tokens+1));
		printf("exec error\n");
		pid_t id = getpid();
		kill(id, SIGTERM);
	}
	else if (p < 0) {
		printf("fork error\n");
	}
	else { // parent
		bg_head = insert_val(bg_head, (int)p, (reply_backup+3));
	}
	return bg_head;
}

void handle_bglist(pval_t* bg_head) {
	print_list(bg_head);
}

pval_t* handle_bg_check(pval_t* bg_head) {
	if (bg_head != NULL) {
		pval_t* node = bg_head;
		while (node != NULL) {
			pid_t curr_pid = (pid_t)node->val;
			int wpid = waitpid(curr_pid, NULL, WNOHANG);
			if (wpid < 0) {
				printf("waitpid error\n");
			} 
			else if (wpid > 0) {
				printf("%d: %s has terminated.\n", node->val, node->command);
				bg_head = remove_val(bg_head, node->val);
			}
			node = node->next;
		}
	}
	return bg_head;
}

void handle_other(char** tokens) {
	pid_t p = fork();
	if (p == 0) { // child
		execvp(tokens[0], tokens);
		printf("exec error\n");
	}
	else if (p < 0) {
		printf("fork error\n");
	}
	else { // parent
		pid_t wpid = waitpid(p, NULL, 0);
	}
}

char* replace_tilda_w_home(char* path, char* home_path) {
	int buff_size = 128;
	int path_i = 0;
	int i = 0;
	char* new_path = malloc(buff_size*sizeof(char));
	if (new_path == NULL) {
		printf("allocation error on malloc. exiting.\n");
		exit(5);
	}
	
	while (path_i < strlen(path)) {
		if (path[path_i] == '~') {
			i = 0;
			int home_i;
			for (home_i = 0; home_i < strlen(home_path); home_i++) {
				new_path[i] = home_path[home_i];
				i++;
				if (i >= buff_size) {
					buff_size = buff_size*2;
					new_path = realloc(new_path, buff_size);
					if (new_path == NULL) {
						printf("allocation error on realloc. exiting.\n");
						exit(5);
					}
				}
			}
		}
		else {
			new_path[i] = path[path_i];
			i++;
		}
		path_i++;
		if (i >= buff_size) {
			buff_size = buff_size*2;
			new_path = realloc(new_path, buff_size);
			if (new_path == NULL) {
				printf("allocation error on realloc. exiting.\n");
				exit(5);
			}
		}
	}
	new_path[i] = '\0';
	return new_path;
}

char** tokenize(char* input) {
	int max_tokens = 5;
	int num_tokens = 0;
	char** tokens = malloc(max_tokens*sizeof(char*));
	if (tokens == NULL) {
		printf("allocation error on malloc. exiting.\n");
		exit(5);
	}
	char* token = NULL;
	token = strtok(input, " ");
	while (token != NULL) {
		tokens[num_tokens++] = token;
		if (num_tokens >= max_tokens) {
			max_tokens = max_tokens*2;
			tokens = realloc(tokens, max_tokens*sizeof(char*));
			if (tokens == NULL) {
				printf("allocation error on realloc. exiting.\n");
				exit(5);
			}
		}
		token = strtok(NULL, " ");
	}
	tokens[num_tokens] = NULL;
	return tokens;
}

char* get_working_directory() {
	int max = 128;
	char* result = malloc(max);
	if (result == NULL) {
		printf("allocation error on malloc. exiting.\n");
		exit(5);
	}
	
	while(1) {
		if (getcwd(result, max) == NULL) {
			max = max*2;
			result = realloc(result, max);
			if (result == NULL) {
				printf("allocation error on realloc. exiting.\n");
				exit(5);
			}
		}
		else {
			break;
		}
	}
	return result;
}