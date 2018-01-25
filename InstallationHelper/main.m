//
//  main.c
//  InstallationHelper
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//
#include <syslog.h>
#include <unistd.h>
#include <stdio.h>

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <string.h>
#include <launch.h>

#import "InstallHelperMessage.h"


//Defines
int performInstall(unsigned char *installerPath);

#define MAX_PATH_SIZE 128
// -1 error
int get_listener_fd() {
	launch_data_t checkin_request = launch_data_new_string(LAUNCH_KEY_CHECKIN);
	if(!checkin_request) {
		syslog(LOG_NOTICE, "Unable to create checkin string!");
		return -1;
	}
	launch_data_t checkin_response = launch_msg(checkin_request);
	if (!checkin_response) {
		syslog(LOG_NOTICE, "Unable to do checkin!");
		return -1;
	}
	if (LAUNCH_DATA_ERRNO == launch_data_get_type(checkin_response)) {
		errno = launch_data_get_errno(checkin_response);
		syslog(LOG_NOTICE, "Error %d getting type of checkin response!", errno);
		return -1;
	}
	launch_data_t the_label = launch_data_dict_lookup(checkin_response, LAUNCH_JOBKEY_LABEL);
	if (!the_label) {
		syslog(LOG_NOTICE, "No Label for job!");
		return -1;
	}
	launch_data_t sockets_dict = launch_data_dict_lookup(checkin_response, LAUNCH_JOBKEY_SOCKETS);
	if (!sockets_dict) {
		syslog(LOG_NOTICE, "No socket found to answer requests on!");
		return -1;
	}
	size_t count = launch_data_dict_get_count(sockets_dict);
	if (count < 1) {
		syslog(LOG_NOTICE, "No socket found to answer requests on!");
		return -1;
	}
	if (1 < count) {
		syslog(LOG_NOTICE, "Some socket(s) will be ignored!");
	}
	launch_data_t listening_fd_array = launch_data_dict_lookup(sockets_dict, "MasterSocket");
	if (!listening_fd_array) {
		syslog(LOG_NOTICE, "MasterSocket not found!");
		return -1;
	}
	count = launch_data_array_get_count(listening_fd_array);
	if (count < 1) {
		syslog(LOG_NOTICE, "No socket found to answer requests on!");
		return -1;
	}
	if (1 < count) {
		syslog(LOG_NOTICE, "Some socket(s) will be ignored!");
	}
	launch_data_t this_listening_fd = launch_data_array_get_index(listening_fd_array, 0);
	int listener_fd = launch_data_get_fd(this_listening_fd);
	if ( listener_fd == -1 ) {
		syslog(LOG_NOTICE, "launch_data_get_fd() failed!");
		return -1;
	}
	if (listen(listener_fd, 5)) {
		syslog(LOG_NOTICE, "listen() failed with %i", errno);
		return -1;
	}
	return listener_fd;
}
/*
 returns -2 for error, -1 for no connection, else file descriptor for connection
 */
int get_connection_fd(int listener_fd) {
	unsigned int size = sizeof(struct sockaddr) + MAX_PATH_SIZE;
	char address_data[size];
	struct sockaddr* address = (struct sockaddr *) &address_data;
	
	struct pollfd fds;
	fds.fd = listener_fd;
	fds.events = POLLIN;
	int bytesReady = poll(&fds, 1, 10000);
	if(bytesReady == -1) {
		syslog(LOG_NOTICE, "poll() error = %d\n", errno);
		return -2;
	}
	if(!bytesReady) return -1;
	
	int connection_fd = accept(listener_fd, address, &size);
	if(connection_fd < 0) {
		syslog(LOG_NOTICE, "accept() returned %i; error = %i!", connection_fd, errno);
		return -2;
	}
	return connection_fd;
}

int respondToRequest() {
	int listener_fd = get_listener_fd();
	if(listener_fd == -1) return 1;
	int connection_fd;
	while (0 <= (connection_fd = get_connection_fd(listener_fd))) {
		struct SUHelperMessage messageIn, messageOut;
		if(readMessage(connection_fd, &messageIn)) break;
		initMessage(messageOut, messageIn.command);
		switch (messageIn.command) {
			case SUM_Version:
				messageOut.dataSize = 3;
				messageOut.data[0] = kVersionPart1;
				messageOut.data[1] = kVersionPart2;
				messageOut.data[2] = kVersionPart3;
				break;
			case SUM_PID: {
				int pid = getpid();
				messageOut.dataSize = sizeof(pid);
				memcpy(messageOut.data, &pid, messageOut.dataSize);
				break;
			}
			case SUM_Install: {
				syslog(LOG_NOTICE, "path is %s", messageIn.data);
				int result = performInstall(messageIn.data);
				messageOut.dataSize = sizeof(result);
				memcpy(messageOut.data, &result, messageOut.dataSize);
				break;
			}
			default:
				syslog(LOG_NOTICE, "Unknown command: %hhd\n", messageIn.command);
				char* message = "Unknown command!";
				messageOut.command = SUM_Error;
				messageOut.dataSize = strlen(message) + 1;    // add trailing \0
				strcpy((char *) messageOut.data, message);
				break;
		}
		int count = messageSize(&messageOut);
		size_t written = write(connection_fd, &messageOut, count);
		if(written != count) {
			syslog(LOG_NOTICE, "tried to write %i, but wrote %zu", count, written);
			break;
		}
		close(connection_fd);
	}
	close(listener_fd);
	if( 0 < connection_fd) {
		close(connection_fd);
	}
	return connection_fd == -1 ? 0 : 1;
}

int performInstall(unsigned char *installerPath)
{
	char command[252];
	sprintf(command,"/usr/sbin/installer -pkg %s -target / ", installerPath);
	return system(command);
}

int main(int argc, const char * argv[]) {
	// insert code here...
	syslog(LOG_NOTICE, "Hello world! uid = %d, euid = %d, pid = %d\n", (int) getuid(), (int) geteuid(), (int) getpid());
	return respondToRequest();
}
