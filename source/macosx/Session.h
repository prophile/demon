#import <Cocoa/Cocoa.h>
#import "Security/Security.h"

@class Transfer;

@interface Session : NSObject
{
	NSMutableArray* _transfers;
	NSMutableArray* _peers;
	RSAKey* _key;
}
- (id)initWithMaxPeerCount:(NSUInteger)maxPeerCount coordinationPort:(uint16_t)coordinationPort transferPort:(uint16_t)transferPort key:(RSAKey*)key;
- (RSAKey*)sessionKey;
- (Transfer*)createTransferWithObjectID:(NSString*)objectHash segmentCount:(NSUInteger)segmentCount segmentHashes:(const char**)hashes totalLength:(NSUInteger)totalLength;
- (void)closeTransfer:(Transfer*)transfer;
- (void)connectToPeer:(NSString*)peerID permanently:(BOOL)perm;
- (void)disconnectPeer:(NSString*)peerID;
- (void)provideObject:(NSString*)objectID withName:(NSString*)name;
- (void)haltProvision:(NSString*)objectID;
- (NSString*)lookupName:(NSString*)name;
@end
