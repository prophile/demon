#import <Cocoa/Cocoa.h>
#import "Security/Security.h"
#import "PeerID.h"
#import "TCP.h"

@interface Peer(NSObject)
{
	NSString* peerID;
	NSFileHandle* connection;
	uint16_t coordinationPort;
	uint16_t transferPort;
	NSString* address;
	RSAKey* publicKey;
	BOOL keep, trust;
	NSDate* lastPacketReception;
	AES192Key* sessionKey;
	NSMutableSet* incomingCommands;
	NSThread* communicationThread;
}
// lowest-level functions
- (BOOL)fullyConnected;
- (void)transmitMessage:(NSString*)message;
- (void)sendObject:(NSString*)objectID segment:(uint64_t)segmentID data:(NSData*)data;
- (void)sendEntireObject:(NSString*)objectID data:(NSData*)entireObjectData;
@end
