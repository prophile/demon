#import <Cocoa/Cocoa.h>
#import <openssl/rsa.h>
#import <openssl/evp.h>

@interface NSData(EncodingMethods)
+ (NSData*)randomDataWithLength:(NSUInteger)length;
- (id)initRandomlyWithLength:(NSUInteger)length;
- (NSString*)encodeHex;
- (NSData*)base64Encode;
- (NSData*)base64Decode;
@end

@interface NSString(EncodingMethods)
- (NSData*)decodeHex;
@end

@interface NSData(Hashing)
- (NSData*)sha1;
@end

@interface RSAKey : NSObject
{
	RSA* rsa;
}
- (id)initWithN:(NSData*)n e:(NSData*)e d:(NSData*)d;
- (id)initWithN:(NSData*)n e:(NSData*)e;
- (id)initWithNewKeyPairOfSize:(NSUInteger)bits usingE:(unsigned long)e;

- (NSData*)n;
- (NSData*)e;
- (NSData*)d;

- (NSData*)privateEncrypt:(NSData*)source;
- (NSData*)publicEncrypt:(NSData*)source;
- (NSData*)privateDecrypt:(NSData*)source;
- (NSData*)privateEncrypt:(NSData*)source;
@end

@interface AES192Key : NSObject
{
	unsigned char key[24];
	unsigned char iv[16];
}
- (id)initWithKey:(NSData*)key initialisationVector:(NSData*)iv;
- (id)initWithRandomKeyAndInitialisationVector;
- (NSData*)key;
- (NSData*)initialisationVector;
- (NSData*)encrypt:(NSData*)source;
- (NSData*)decrypt:(NSData*)source;
@end
