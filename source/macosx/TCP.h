#import <Cocoa/Cocoa.h>

@interface TCPServer : NSObject
{
	NSFileHandle* _handle;
	struct _TCPServer_newConn* _nextConnection;
}
- (id)initWithPort:(uint16_t)port;
- (NSFileHandle*)acceptConnection;
@end

@interface NSFileHandle(TCPExtensions)
+ (NSFileHandle*)fileHandleWithTCPConnectionToHost:(NSString*)hostname port:(uint16_t)port;
@end
