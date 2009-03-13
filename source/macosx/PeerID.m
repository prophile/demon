#import "PeerID.h"

const NSString* publicIPURL = @"http://rabidtinker.mine.nu/pubip.php";

NSString* GetPublicIP ()
{
	static NSString* cachedIP = nil;
	if (!cachedIP)
	{
		NSData* ipData = [NSData dataWithContentsOfURL:[NSURL URLWithString:publicIPURL]];
		cachedIP = [[NSString alloc] initWithData:[ipData subdataWithRange:NSMakeRange(0, [ipData length] - 1)] encoding:NSASCIIStringEncoding];
	}
	return cachedIP;
}

NSString* GetPeerSpecifier ( uint16_t coordinationPort, uint16_t transferPort, RSAKey* localKey )
{
	return [NSString stringWithFormat:@"%@;%d;%d;%@", GetPublicIP(), coordinationPort, transferPort, [[localKey n] base64Encode]];
}
