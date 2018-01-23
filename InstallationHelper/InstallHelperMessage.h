//
//  InstallHelperMessage.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/23/18.
//

#ifndef InstallHelperMessage_h
#define InstallHelperMessage_h

#include <stdbool.h>

#define kSocketPath "/var/run/com.zoomsupport.InstallationHelper.socket"
#define kHelperIdentifier "com.zoomsupport.InstallationHelper"
#define kVersionPart1 1
#define kVersionPart2 0
#define kVersionPart3 0

enum SUInstallationHelperCommand
{
	SUM_Error = 0,
	SUM_Version = 1,
	SUM_PID = 2,
	SUM_Install = 3
};

//Command structure version
#define kMessageVersion 1

struct SUHelperMessage
{
	unsigned char version;		//kMessageVersion
	unsigned char command;		//SUInstallationHelperCommand
	unsigned char dataSize;		//0 to 252
	unsigned char data[252];	//command data
};

#define messageSize(message_p) sizeof(*message_p) - sizeof((message_p)->data) + (message_p)->dataSize
#define initMessage(m, c) { m.version = kMessageVersion; m.command = c; m.dataSize = 0; }

int readMessage(int fd, struct SUHelperMessage * message);
int sendMessage(const struct SUHelperMessage * messageOut, struct SUHelperMessage * messageIn);
bool isCurrentVersion(void);

#endif /* InstallHelperMessage_h */
