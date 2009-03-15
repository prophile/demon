#ifndef __included_libdop_h
#define __included_libdop_h

#include <stdbool.h>
#include <inttypes.h>

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct _DOP_Session DOP_Session;

typedef struct _DOP_Plugin
{
	void (*onConnect)(DOP_Session* session, void* userdata, const char* peerID);
	void (*onDisconnect)(DOP_Session* session, void* userdata, const char* peerID);
	const void* (*onRequest)(DOP_Session* session, void* userdata, const char* objectID, uint64_t segmentNumber, const char* peer, uint64_t* length);
	const void* (*onRequestFull)(DOP_Session* session, void* userdata, const char* objectID, uint64_t segmentNumber, const char* peer, uint64_t* length);
	bool (*onReceive)(DOP_Session* session, void* userdata, const char* objectID, uint64_t segmentNumber, const char* peer, const void* data, uint64_t length);
	bool (*onReceiveFull)(DOP_Session* session, void* userdata, const char* objectID, const char* peer, const void* data, uint64_t length);
	bool (*onExtendedCommand)(DOP_Session* session, void* userdata, const char* command, const char* line, const char* peer);
	void* userdata;
} DOP_Plugin;

typedef enum _DOP_Transport
{
	DOP_TRANSPORT_TCP,
	DOP_TRANSPORT_HTTP,
	DOP_TRANSPORT_HTTPS,
	DOP_TRANSPORT_ENET
} DOP_Transport;

DOP_Session* DOP_OpenSession ( int maxPeerCount, uint16_t port, DOP_Transport transport, const void* keyData, unsigned int keyLength ); // pass 0 for the key to generate a new one.
void DOP_CloseSession ( DOP_Session* session );

void DOP_AddPlugin ( DOP_Session* session, DOP_Plugin* plugin );

void DOP_Update ( DOP_Session* session );

void DOP_SendExtendedCommand ( DOP_Session* session, const char* command, const char* line, const char* peer, bool broadcast ); // behaviours are as follows:
//  if broadcast == false and peer == null, send to a peer at random
//  if broadcast == true  and peer == null, send to all
//  if broadcast == true  and peer != null, send to all but the given peer
//  if broadcast == false and peer != null, send to the given peer

const void* DOP_SessionKey ( DOP_Session* session, unsigned int* length );
const char* DOP_PeerID ( DOP_Session* session );

void DOP_RegisterObject ( DOP_Session* session, const char* name, const char* objectID );
void DOP_UnregisterObject ( DOP_Session* session, const char* name );

void DOP_Connect ( DOP_Session* session, const char* peerID, bool trust, bool keep );
void DOP_Disconnect ( DOP_Session* session, const char* peerID );

bool DOP_CanTrust ( DOP_Session* session, const char* peerID );
const char* DOP_LookupObject ( DOP_Session* session, const char* objectName );

#ifdef __cplusplus
}
#endif

#endif