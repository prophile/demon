#import "Peer.h"
#import <stdio.h>

static FILE* devurandom = NULL;

@implementation Peer

@synthesize delegate;

- (BOOL)fullyConnected
{
	return (sessionKey ? YES : NO);
}

- (void)transmitMessage:(NSString*)message
{
	NSData* dataObject = [message dataUsingEncoding:NSASCIIStringEncoding];
	TransportMessage* message = [[TransportMessage alloc] init];
	message.data = dataObject;
	message.reliable = YES;
	message.orderingChannel = 0;
	[transport sendMessage:message];
	[message release];
}

- (void)sendObject:(NSString*)objectID segment:(uint64_t)segmentID data:(NSData*)data
{
	if (!devurandom)
	{
		devurandom = fopen("/dev/urandom", "r");
	}
	uint64_t callsign;
	fread(&callsign, 8, 1, devurandom);
	NSString* expectMessage = [NSString stringWithFormat:@"EXPECT %016llX %@ %llu %u", callsign, objectID, segmentID, [data length]];
	[self transmitMessage:expectMessage];
	NSMutableData* messageData = [NSMutableData data];
	callsign = NSSwapHostLongLongToBig(callsign);
	[messageData appendBytes:&callsign length:8];
	[messageData appendData:data];
	TransportMessage* message = [[TransportMessage alloc] init];
	message.data = messageData;
	message.reliable = YES;
	message.orderingChannel = 1;
	[transport sendMessage:message];
	[message release];
}

- (void)sendEntireObject:(NSString*)objectID data:(NSData*)data
{
	if (!devurandom)
	{
		devurandom = fopen("/dev/urandom", "r");
	}
	uint64_t callsign;
	fread(&callsign, 8, 1, devurandom);
	NSString* expectMessage = [NSString stringWithFormat:@"EXPECT %016llX %@ full %u", callsign, objectID, [data length]];
	[self transmitMessage:expectMessage];
	NSMutableData* messageData = [NSMutableData data];
	callsign = NSSwapHostLongLongToBig(callsign);
	[messageData appendBytes:&callsign length:8];
	[messageData appendData:data];
	TransportMessage* message = [[TransportMessage alloc] init];
	message.data = messageData;
	message.reliable = YES;
	message.orderingChannel = 1;
	[transport sendMessage:message];
	[message release];
}

- (BOOL)isTrusted
{
	return trust;
}

- (void)declareTrust
{
	trust = YES;
}

@end
