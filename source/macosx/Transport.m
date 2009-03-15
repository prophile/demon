#import "Transport.h"

@implementation TransportMessage

@synthesize data;
@synthesize orderingChannel;
@synthesize reliable;

- (id)init
{
	id s = [super init];
	if (s == self)
	{
		reliable = YES;
	}
	return s;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

@end

@implementation Transport
- (id)init
{
	id s = [super init];
	if (s == self)
	{
		modifiers = [[NSMutableArray alloc] init];
	}
	return s;
}

- (void)dealloc
{
	[modifiers release];
	[super dealloc];
}

- (void)addModifiers:(TransportMessageModifier*)modifier
{
	[modifiers addObject:modifier];
}

- (void)removeModifier:(TransportMessageModifier*)modifier
{
	[modifiers removeObject:modifier];
}

- (void)sendMessage:(TransportMessage*)message
{
}
@end

@implementation TransportMessageModifier
- (NSData*)encodeMessageData:(NSData*)data
{
	return data;
}

- (NSData*)decodeMessageData:(NSData*)data
{
	return data;
}
@end

@implementation AES192TransportMessageModifier
@synthesize key;

- (id)initWithAES192Key:(AES192Key*)aKey
{
	id s = [super init];
	if (s == self)
	{
		key = [aKey retain];
	}
	return s;
}

- (void)dealloc
{
	[key release];
	[super dealloc];
}

- (NSData*)encodeMessageData:(NSData*)data
{
	return [key encrypt:data];
}

- (NSData*)decodeMessageData:(NSData*)data
{
	return [key decrypt:data];
}
@end

const NSString* TransportMessageReceivedNotification = @"TransportMessageReceivedNotification";
const NSString* TransportMessageReceived = @"TransportMessageReceived";
const NSString* TransportConnectionClosedNotification = @"TransportConnectionClosedNotification";
