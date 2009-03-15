#import <Cocoa/Cocoa.h>
#import "Security/Security.h"
#import "PeerID.h"
#import "Transport.h"

@interface Peer : NSObject
{
	NSString* peerID;
	Transport* transport;
	RSAKey* key;
	BOOL keep, trust, host;
	NSDate* lastPacketReception;
	AES192Key* sessionKey;
	id delegate;
}
@property (retain) id delegate;
- (id)initWithTransport:(Transport*)aTransport asHost:(BOOL)isHost keep:(BOOL)doKeep trust:(BOOL)canTrust peerID:(NSString*)id rsaKey:(RSAKey*)myKey;
// lowest-level functions
- (BOOL)fullyConnected;
- (void)transmitMessage:(NSString*)message;
- (void)sendObject:(NSString*)objectID segment:(uint64_t)segmentID data:(NSData*)data;
- (void)sendEntireObject:(NSString*)objectID data:(NSData*)entireObjectData;
// higher level
- (BOOL)isTrusted;
- (void)declareTrust;
@end
