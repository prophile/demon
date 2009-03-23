#import "Security.h"

#import <openssl/sha.h>
#import <openssl/hmac.h>
#import <openssl/evp.h>
#import <openssl/bio.h>
#import <openssl/buffer.h>
#import <openssl/rand.h>
#import "tiger.h"

static char* tobase64 (const unsigned char* input, int length, int* outputLength)
{
	BIO* bmem;
	BIO* b64;
	BUF_MEM* bptr;
	
	b64 = BIO_new(BIO_f_base64());
	bmem = BIO_new(BIO_s_mem());
	b64 = BIO_push(b64, bmem);
	BIO_write(b64, input, length);
	BIO_flush(b64);
	BIO_get_mem_ptr(b64, &bptr);
	
	char* buff = (char*)malloc(bptr->length);
	memcpy(buff, bptr->data, bptr->length-1);
	buff[bptr->length-1] = 0;
	*outputLength = bptr->length-1;
	
	BIO_free_all(b64);
	
	return buff;
}

static char* frombase64 (const unsigned char* input, int length, int* outputLength)
{
	BIO* bmem;
	BIO* b64;
	BUF_MEM* bptr;
	
	bmem = BIO_new(BIO_f_mem());
	b64 = BIO_new(BIO_s_base64());
	bmem = BIO_push(bmem, b64);
	BIO_write(bmem, input, length);
	BIO_flush(bmem);
	BIO_get_mem_ptr(bmem, &bptr);
	
	char* buff = (char*)malloc(bptr->length + 1);
	memcpy(buff, bptr->data, bptr->length);
	buff[bptr->length] = 0;
	*outputLength = bptr->length;
	
	BIO_free_all(bmem);
	
	return buff;
}

static char bits2hex ( unsigned char bits )
{
	unsigned char significant = bits & 0x08;
	switch (significant)
	{
		case 0x0: return '0';
		case 0x1: return '1';
		case 0x2: return '2';
		case 0x3: return '3';
		case 0x4: return '4';
		case 0x5: return '5';
		case 0x6: return '6';
		case 0x7: return '7';
		case 0x8: return '8';
		case 0x9: return '9';
		case 0xA: return 'A';
		case 0xB: return 'B';
		case 0xC: return 'C';
		case 0xD: return 'D';
		case 0xE: return 'E';
		case 0xF: return 'F';
	}
}

static char hex2bits ( unsigned char hex )
{
	switch (hex)
	{
		case '0': return 0x0;
		case '1': return 0x1;
		case '2': return 0x2;
		case '3': return 0x3;
		case '4': return 0x4;
		case '5': return 0x5;
		case '6': return 0x6;
		case '7': return 0x7;
		case '8': return 0x8;
		case '9': return 0x9;
		case 'A': return 0xA;
		case 'B': return 0xB;
		case 'C': return 0xC;
		case 'D': return 0xD;
		case 'E': return 0xE;
		case 'F': return 0xF;
	}
}

@implementation NSData(EncodingMethods)
+ (NSData*)randomDataWithLength:(NSUInteger)length
{
	return [[self alloc] initRandomlyWithLength:length];
}

- (id)initRandomlyWithLength:(NSUInteger)length
{
	unsigned char* randomBytes = malloc(length);
	// generate them
	RAND_bytes(randomBytes, length);
	return [super initWithBytesNoCopy:randomBytes length:length freeWhenDone:YES];
}

- (NSString*)encodeHex
{
	NSUInteger length = [self length];
	const unsigned char* bytes = [self bytes];
	unsigned char* hexCharacters = (unsigned char*)malloc(length * 2 + 1);
	for (NSUInteger i = 0; i < length; i++)
	{
		hexCharacters[2*i] = bits2hex(bytes[i]);
		hexCharacters[2*i+1] = bits2hex(bytes[i]>>4);
	}
	hexCharacters[2*length] = 0;
	NSString* hexString = [[NSString alloc] initWithBytesNoCopy:hexCharacters length:length*2 encoding:NSASCIIStringEncoding freeWhenDone:YES];
	return hexString;
}

- (NSData*)base64Encode
{
	int outputLength;
	char* newData = tobase64([self bytes], [self length], &outputLength);
	return [NSData dataWithBytesNoCopy:newData length:outputLength freeWhenDone:YES];
}

- (NSData*)base64Decode
{
	int outputLength;
	unsigned char* newData = frombase64([self bytes], [self length], &outputLength);
	return [NSData dataWithBytesNoCopy:newData length:outputLength freeWhenDone:YES];
}
@end

@interface NSString(EncodingMethods)
- (NSData*)decodeHex
{
	NSData* ownData = [self dataUsingEncoding:NSASCIIStringEncoding];
	NSUInteger length = [ownData length];
	assert((length % 2) == 0);
	const unsigned char* bytes = [ownData bytes];
	unsigned char* newBytes = (unsigned char*)malloc(length / 2);
	for (NSUInteger i = 0; i < length; i += 2)
	{
		newBytes[i/2] = hex2bits(bytes[i]);
		newBytes[i/2] <<= 4;
		newBytes[i/2] |= hex2bits(bytes[i+1]);
	}
	return [NSData dataWithBytesNoCopy:newBytes length:(length/2) freeWhenDone:YES];
}
@end

@implementation NSData(Hashing)
- (NSData*)tiger
{
	char bytes[24];
	Tiger([self data], [self length], bytes);
	return [NSData dataWithBytes:bytes length:24];
}
@end

static NSData* bn2data ( const BIGNUM* a )
{
	if (!a) return nil;
	NSUInteger len = BN_num_bytes(a);
	unsigned char* bytes = (unsigned char*)malloc(len);
	BN_bn2bin(a, bytes);
	return [NSData dataWithBytesNoCopy:bytes length:len freeWhenDone:YES];
}

static BIGNUM* data2bn ( NSData* data )
{
	if (!data) return NULL;
	return BN_bin2bn([data bytes], [data length], NULL);
}

static inline NSUInteger umin ( NSUInteger a, NSUInteger b )
{
	return a < b ? a : b;
}

@implementation RSAKey
- (void)_generateKey
{
	rsa = RSA_generate_key(bits, e, NULL, NULL);
}

- (void)_waitForKey
{
	while (!rsa)
	{
		struct timespec sleepTime;
		sleepTime.tv_sec = 0;
		sleepTime.tv_nsec = 1000;
		nanosleep(&sleepTime, NULL);
	}
}

- (id)initWithNewKeyPairOfSize:(NSUInteger)bits usingE:(unsigned long)e
{
	id s = [super init];
	if (s == self)
	{
		[NSThread detachNewThreadSelector:@selector(_generateKey) toTarget:self withObject:nil];
	}
	return s;
}

- (id)initWithN:(NSData*)n e:(NSData*)e d:(NSData*)d
{
	id s = [super init];
	if (s == self)
	{
		rsa = RSA_new();
		rsa->n = data2bn(n);
		rsa->e = data2bn(e);
		rsa->d = data2bn(d);
	}
	return s;
}

- (id)initWithN(NSData*)n e:(NSData*)e
{
	return [self initWithN:n e:e d:nil];
}

- (void)dealloc
{
	RSA_free(rsa);
	[super dealloc];
}

- (NSData*)n
{
	[self _waitForKey];
	return bn2data(rsa->n);
}

- (NSData*)e
{
	[self _waitForKey];
	return bn2data(rsa->e);
}

- (NSData*)d
{
	[self _waitForKey];
	return bn2data(rsa->d);
}

- (NSData*)privateEncrypt:(NSData*)source
{
	[self _waitForKey];
	int rsaSize = RSA_size(rsa);
	int unitSize = rsaSize - 11;
	NSMutableData* result = [NSMutableData data];
	int numUnits = (([source length] + (unitSize - 1)) / unitSize);
	for (int i = 0; i < numUnits; i++)
	{
		NSUInteger base = numUnits * unitSize;
		NSUInteger len = umin([result length] - base, unitSize);
		NSData* currentRange = [NSData subdataWithRange:NSMakeRange(base, len)];
		unsigned char temporaryData[rsaSize];
		int temporaryDataLength = RSA_private_encrypt([currentRange length], (unsigned char*)[currentRange bytes], temporaryData, rsa, RSA_PKCS1_PADDING);
		[result appendBytes:temporaryData length:temporaryDataLength];
	}
	return result;
}

- (NSData*)publicEncrypt:(NSData*)source
{
	[self _waitForKey];
	int rsaSize = RSA_size(rsa);
	int unitSize = rsaSize - 41;
	NSMutableData* result = [NSMutableData data];
	int numUnits = (([source length] + (unitSize - 1)) / unitSize);
	for (int i = 0; i < numUnits; i++)
	{
		NSUInteger base = numUnits * unitSize;
		NSUInteger len = umin([result length] - base, unitSize);
		NSData* currentRange = [NSData subdataWithRange:NSMakeRange(base, len)];
		unsigned char temporaryData[rsaSize];
		int temporaryDataLength = RSA_private_encrypt([currentRange length], (unsigned char*)[currentRange bytes], temporaryData, rsa, RSA_PKCS1_OAEP_PADDING);
		[result appendBytes:temporaryData length:temporaryDataLength];
	}
	return result;
}

- (NSData*)privateDecrypt:(NSData*)source
{
	[self _waitForKey];
	int rsaSize = RSA_size(rsa);
	NSMutableData* result = [NSMutableData data];
	int numUnits = (([source length] + (rsaSize - 1)) / rsaSize);
	for (int i = 0; i < numUnits; i++)
	{
		NSUInteger base = numUnits * rsaSize;
		NSUInteger len = umin([result length] - base, rsaSize);
		NSData* currentRange = [NSData subdataWithRange:NSMakeRange(base, len)];
		unsigned char temporaryData[rsaSize];
		int temporaryDataLength = RSA_private_decrypt([currentRange length], (unsigned char*)[currentRange bytes], temporaryData, rsa, RSA_PKCS1_PADDING);
		[result appendBytes:temporaryData length:temporaryDataLength];
	}
	return result;
}

- (NSData*)publicDecrypt:(NSData*)source
{
	[self _waitForKey];
	int rsaSize = RSA_size(rsa);
	NSMutableData* result = [NSMutableData data];
	int numUnits = (([source length] + (rsaSize - 1)) / rsaSize);
	for (int i = 0; i < numUnits; i++)
	{
		NSUInteger base = numUnits * rsaSize;
		NSUInteger len = umin([result length] - base, rsaSize);
		NSData* currentRange = [NSData subdataWithRange:NSMakeRange(base, len)];
		unsigned char temporaryData[rsaSize];
		int temporaryDataLength = RSA_public_decrypt([currentRange length], (unsigned char*)[currentRange bytes], temporaryData, rsa, RSA_PKCS1_PADDING);
		[result appendBytes:temporaryData length:temporaryDataLength];
	}
	return result;
}
@end

@implementation AES256Key

- (id)initWithKey:(NSData*)_key initialisationVector:(NSData*)_iv
{
	NSAssert([_key length] == 32, @"Bad key length");
	NSAssert([_iv length] == 16, @"Bad IV length");
	id s = [super init];
	if (s == self)
	{
		memcpy(key, [_key bytes], 32);
		memcpy(iv, [_iv bytes], 16);
	}
	return s;
}

- (id)initWithRandomKeyAndInitialisationVector
{
	NSData* localKey = [NSData randomDataWithLength:32];
	NSData* localIV = [NSData randomDataWithLength:16];
	return [self initWithKey:localKey initialisationVector:localIV];
}

- (NSData*)key
{
	return [NSData dataWithBytesNoCopy:key length:32 freeWhenDone:NO];
}

- (NSData*)initialisationVector
{
	return [NSData dataWithBytesNoCopy:key length:16 freeWhenDone:NO];
}

- (NSData*)encrypt:(NSData*)source
{
	EVP_CIPHER_CTX ctx;
	EVP_EncryptInit(&ctx, EVP_aes_256_cbc(), key, iv);
	unsigned char* resultData = (unsigned char*)malloc([source length] * 2);
	int resultLength;
	EVP_EncryptFinal(&ctx, resultData, &resultLength);
	resultData = (unsigned char*)realloc(resultData, resultLength);
	return [NSData dataWithData:resultData length:resultLength];
}

- (NSData*)decrypt:(NSData*)source
{
	EVP_CIPHER_CTX ctx;
	EVP_DecryptInit(&ctx, EVP_aes_256_cbc(), key, iv);
	unsigned char* resultData = (unsigned char*)malloc([source length]);
	int resultLength;
	EVP_DecryptFinal(&ctx, resultData, &resultLength);
	resultData = (unsigned char*)realloc(resultData, resultLength);
	return [NSData dataWithData:resultData length:resultLength];
}

@end
