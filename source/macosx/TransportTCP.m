#import "TransportTCP.h"

@implementation TransportTCP

- (void)_dispatchMessage:(TransportMessage*)message
{
	NSDictionary* infoDictionary = [NSDictionary dictionaryWithObject:message forKey:TransportMessageReceived];
	[[NSNotificationCenter defaultCenter] postNotificationName:TransportMessageReceivedNotification object:self userInfo:infoDictionary];
}

- (void)_handleNewData:(NSData*)packetData
{
	if (expectedPacketLength == 0)
	{
		NSAssert([packetData length] >= 4);
		// new packet
		uint32_t len;
		len = *(uint32_t*)[packetData bytes];
		len = ntohl(len);
		BOOL order1 = len & 0x80000000;
		len &= ~0x80000000;
		packetOrderingChannel = order1 ? 1 : 0;
		expectedPacketLength = len;
		if ([packetData length] > 4)
		{
			[packetBuffer setData:[packetData subdataWithRange:NSMakeRange(4, [packetData length] - 4)]];
		}
		else
		{
			[packetBuffer setLength:0];
		}
	}
	else
	{
		[packetBuffer appendData:packetData];
	}
	if ([packetBuffer length] > expectedPacketLength)
	{
		NSData* actualMessage = [packetBuffer subdataWithRange:NSMakeRange(0, expectedPacketLength)];
		NSData* nextPacket = [packetBuffer subdataWithRange:NSMakeRange(expectedPacketLength, [packetBuffer length] - expectedPacketLength)];
		TransportMessage* message = [[TransportMessage alloc] init];
		message.data = actualMessage;
		message.orderingChannel = packetOrderingChannel;
		message.reliable = YES;
		[self _dispatchMessage:message];
		[message release];
		expectedPacketLength = 0;
		[self _handleNewData:message];
	}
	else if ([packetBuffer length] == expectedPacketLength)
	{
		TransportMessage* message = [[TransportMessage alloc] init];
		message.data = [[packetBuffer copy] autorelease];
		message.orderingChannel = packetOrderingChannel;
		message.reliable = YES;
		[self _dispatchMessage:message];
		[message release];
		expectedPacketLength = 0;
	}
}

- (void)_gotPacket:(NSNotification*)note
{
	NSData* packetData = [[note userInfo] objectForKey:NSFileHandleNotificationDataItem];
	[self _handleNewData:packetData];
	[fileHandle readInBackgroundAndNotify];
}

- (id)initWithFileHandle:(NSFileHandle*)handle
{
	id s = [super init];
	if (s == self)
	{
		fileHandle = [handle retain];
		[fileHandle readInBackgroundAndNotify];
		[[NSNotificationCenter defaultNotificationCenter] addObserver:self selector:@selector(_gotPacket:) name:NSFileHandleReadCompletionNotification object:fileHandle];
		packetBuffer = [[NSMutableData alloc] init];
	}
	return s;
}

- (id)initWithConnectionToHost:(NSString*)host port:(uint16_t)port
{
	return [self initWithFileHandle:[NSFileHandle fileHandleWithTCPConnectionToHost:host port:port]];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultNotificationCenter] removeObserver:self];
	[packetBuffer release];
	[fileHandle release];
	[super dealloc];
}

- (void)sendMessage:(TransportMessage*)message
{
	NSUInteger numModifiers = [modifiers count];
	for (NSUInteger i = 0; i < numModifiers; i++)
	{
		message.data = [[modifiers objectAtIndex:i] encodeMessageData:message.data];
	}
	NSMutableData* entirePacket = [NSMutableData data];
	uint32_t len = [message.data length];
	if (message.orderingChannel & 1)
		len |= 0x80000000;
	len = htonl(len);
	[entirePacket appendBytes:&len length:4];
	[entirePacket appendData:message.data];
	[fileHandle writeData:entirePacket];
}

@end
