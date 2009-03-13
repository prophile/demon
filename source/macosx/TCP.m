#import "TCP.h"

struct _TCPServer_newConn
{
	NSFileHandle* handle;
	struct _TCPServer_newConn* next;
};

@implementation TCPServer

- (void)_gotConnection:(NSNotification*)notification
{
	NSFileHandle* newHandle = [[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
	[newHandle retain];
	struct _TCPServer_newConn* connection = malloc(sizeof(struct _TCPServer_newConn));
	connection->handle = newHandle;
	if (_nextConnection)
	{
		struct _TCPServer_newConn* iter = _nextConnection;
		while (iter->next) iter = iter->next;
		iter->next = connection;
	}
	else
	{
		_nextConnection = connection;
	}
}

- (id)initWithPort:(uint16_t)port
{
	id s = [super init];
	if (s == self)
	{
		int sock = socket(AF_INET, SOCK_STREAM, 6);
		struct sockaddr_in address;
		socklen_t addrlen = sizeof(address);
		address.sin_family = AF_INET;
		address.sin_port = htons(port);
		address.sin_address = INADDR_ANY;
		bind(sock, &address, addrlen);
		listen(sock, 5);
		_handle = [[NSFileHandle alloc] initWithFileDescriptor:sock closeOnDealloc:YES];
		[_handle acceptConnectionInBackgroundAndNotify];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gotConnection) name:NSFileHandleConnectionAcceptedNotification object:_handle];
	}
	return s;
}

- (NSFileHandle*)acceptConnection
{
	if (_nextConnection)
	{
		NSFileHandle* conn = _nextConnection->handle;
		struct _TCPServer_newConn* oldNext = _nextConnection;
		_nextConnection = _nextConnection->next;
		free(oldNext);
		return [conn autorelease];
	}
	else
	{
		return nil;
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_handle release];
	[super dealloc];
}

@end

@implementation NSFileHandle(TCPExtensions)
+ (NSFileHandle*)fileHandleWithTCPConnectionToHost:(NSString*)hostname port:(uint16_t)port
{
	NSHost* remoteHost = [NSHost hostWithName:hostname];
	NSString* address = [remoteHost address];
	BOOL isIPv6 = [address rangeOfString:@":"].location != NSNotFound;
	int sock;
	if (isIPv6)
	{
		sock = socket(AF_INET6, SOCK_STREAM, 6);
		struct sockaddr_in6 address;
		socklen_t addrlen = sizeof(address);

		address.sin_len = sizeof(address);
		address.sin_family = AF_INET6;
		address.sin_flowinfo = 0;
		address.sin_port = 0;
		address.sin_address = in6addr_any;
		bind(sock, &address, addlen);

		address.sin_len = sizeof(address);
		address.sin_family = AF_INET6;
		address.sin_flowinfo = 0;
		address.sin_port = htons(port);
		inet_pton(AF_INET6, [address UTF8String], &(address.sin_address));
		connect(sock, &address, addrlen);
	}
	else
	{
		sock = socket(AF_INET, SOCK_STREAM, 6);
		struct sockaddr_in address;
	
		socklen_t addrlen = sizeof(address);
		address.sin_family = AF_INET;
		address.sin_port = 0;
		address.sin_address = INADDR_ANY;
		bind(sock, &address, addrlen);

		address.sin_family = AF_INET;
		address.sin_port = htons(port);
		inet_pton(AF_INET, [address UTF8String], &(address.sin_address));
		connect(sock, &address, addrlen);
	}
	return [[[NSFileHandle alloc] initWithFileDescriptor:sock closeOnDealloc:YES] autorelease];
}
@end
