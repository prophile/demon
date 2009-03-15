#import <Cocoa/Cocoa.h>
#import "Security/Security.h"

@interface TransportMessage : NSObject
{
	NSData* data;
	NSUInteger orderingChannel;
	BOOL reliable;
}
@property (retain) NSData* data;
@property NSUInteger orderingChannel;
@property BOOL reliable;
@end

@class TransportMessageModifier;

@interface Transport : NSObject
{
@protected
	NSMutableArray* modifiers;
}
- (void)addModifier:(TransportMessageModifier*)modifier;
- (void)removeModifier:(TransportMessageModifier*)modifier;
- (void)sendMessage:(TransportMessage*)message;
@end

@interface TransportMessageModifier : NSObject
{
}
- (NSData*)encodeMessageData:(NSData*)data;
- (NSData*)decodeMessageData:(NSData*)data;
@end

@interface AES192TransportMessageModifier
{
	AES192Key* key;
}
@property (retain, readonly) AES192Key* key;
- (id)initWithAES192Key:(AES192Key*)key;
@end

extern const NSString* TransportMessageReceivedNotification;
extern const NSString* TransportMessageReceived;
extern const NSString* TransportConnectionClosedNotification;
