#import <Cocoa/Cocoa.h>
#import "Security/Security.h"

NSString* GetPublicIP ();
NSString* GetPeerSpecifier ( uint16_t coordinationPort, uint16_t transferPort, RSAKey* localKey );
void SplitPeerSpecifier ( NSString* spec, NSString** address, uint16_t* coordinationPort, uint16_t* transferPort, RSAKey** publicKey );
