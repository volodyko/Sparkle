//
//  main.c
//  InstallationHelper
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//
#include <syslog.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, const char * argv[]) {
	// insert code here...
	syslog(LOG_NOTICE, "Hello world! uid = %d, euid = %d, pid = %d\n", (int) getuid(), (int) geteuid(), (int) getpid());
	return 0;
}
