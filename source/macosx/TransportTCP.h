#import "Transport.h"
#import "TCP.h"

@interface TransportTCP : Transport
{
	NSFileHandle* fileHandle;
	NSMutableData* packetBuffer;
	uint32_t expectedPacketLength;
	NSUInteger packetOrderingChannel;
}
- (id)initWithConnectionToHost:(NSString*)host port:(uint16_t)port;
- (id)initWithFileHandle:(NSFileHandle*)handle;
- (void)sendMessage:(TransportMessage*)message;
@end
