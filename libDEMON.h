#ifndef __included_libdemon_h
#define __included_libdemon_h

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stdint.h>

typedef struct _DEMON_Session DEMON_Session;

typedef enum _DEMON_Transport
{
	DEMON_TRANSPORT_HTTP,
	DEMON_TRANSPORT_HTTPS,
	DEMON_TRANSPORT_TCP,
	DEMON_TRANSPORT_ENET
} DEMON_Transport;

DEMON_Session* DEMON_OpenSession ( const char* clientName, DEMON_Transport transport, uint16_t port, int maxClients, const void* key, unsigned keyLength );
void DEMON_CloseSession ( DEMON_Session* session );

void DEMON_LoadTrustDB ( DEMON_Session* session, const void* db, uint64_t length );
void* DEMON_SaveTrustDB ( DEMON_Session* session, uint64_t* length ); // this returns a new pointer

const void* DEMON_SessionKey ( DEMON_Session* session, unsigned* length );
const char* DEMON_PeerID ( DEMON_Session* session );

void DEMON_Connect ( DEMON_Session* session, const char* peer, bool trust, bool keep );
void DEMON_Disconnect ( DEMON_Session* session, const char* peer );

typedef struct _DEMON_BandwidthCap
{
	unsigned maxUploadRate;
	unsigned maxDownloadRate;
} DEMON_BandwidthCap;

DEMON_BandwidthCap DEMON_GetBandwidthCap ( DEMON_Session* session );
void DEMON_SetBandwidthCap ( DEMON_Session* session, DEMON_BandwidthCap cap );

typedef struct _DEMON_Statistics
{
	unsigned uploadRate, downloadRate;
	float sessionRatio;
	unsigned totalUpload, totalDownload;
} DEMON_Statistics;

DEMON_Statistics DEMON_GetStatistics ( DEMON_Session* session );

typedef struct _DEMON_Object
{
	uint64_t length;
	uint64_t pieceCount; // if left at 0, DEMON_RegisterObject will convert to ceil(length / 512)
	const char** pieceHashes; // often left at NULL; if not, must point to an array of SHA1 hashes of pieces.
	void* userdata;
	bool (*providePieceCallback)(struct _DEMON_Object* object, void* userdata, uint64_t pieceID, void** buffer, uint64_t* length); // buffer must point to newly malloc'd memory
	bool (*havePieceCallback)(struct _DEMON_Object* object, void* userdata, uint64_t pieceID);
	bool (*receivePieceCallback)(struct _DEMON_Object* object, void* userdata, uint64_t pieceID, const void* buffer, uint64_t length);
	uint64_t (*pickPieceCallback)(struct _DEMON_Object* object, void* userdata); // return DEMON_OBJECT_COMPLETE if all pieces are had
	void (*deleteObjectCallback)(struct _DEMON_Object* object, void* userdata);
	char hash[49]; // read-only
	bool shouldUpload, shouldDownload;
	bool isPurgeable; // if this is true, can be deleted at will by the object
	// internal
	uint64_t lastUseTime;
} DEMON_Object;

#define DEMON_OBJECT_COMPLETE (~(uint64_t)0)

const char* DEMON_GenerateTiger ( const void* buffer, uint64_t length );
const char* DEMON_GenerateTigerFile ( const char* path );

DEMON_Object* DEMON_NewObject ( const char* hash ); // a completely blank object, except for the hash
DEMON_Object* DEMON_NewObjectMemoryDownload ( const char* objectID, void* buffer, uint64_t length );
DEMON_Object* DEMON_NewObjectMemoryUpload ( const void* buffer, uint64_t length );
DEMON_Object* DEMON_NewObjectFile ( const char* path, const char* objectID, uint64_t length );
DEMON_Object* DEMON_NewObjectEmpty ();
void DEMON_DeleteObject ( DEMON_Object* object );

void DEMON_RegisterObject ( DEMON_Session* session, DEMON_Object* object );
void DEMON_UnregisterObject ( DEMON_Session* session, DEMON_Object* object );

void DEMON_BindName ( DEMON_Session* session, const char* name, DEMON_Object* object );
const char* DEMON_LookupName ( DEMON_Session* session, uint64_t* length );

typedef bool (*DEMON_PluginCallback)(DEMON_Session* session, void* userdata, const char* peerName, unsigned pluginCommand, const char* key, const void* data);

void DEMON_RegisterPlugin ( DEMON_Session* session, DEMON_PluginCallback callback, void* userdata, const char** handledCommands );
void DEMON_UnregisterPlugin ( DEMON_Session* session, DEMON_PluginCallback callback, void* userdata );

typedef DEMON_Object* (*DEMON_ObjectProvider)(DEMON_Session* session, void* userdata, const char* objectID);

void DEMON_RegisterObjectProvider ( DEMON_Session* session, DEMON_ObjectProvider provider, void* userdata );
void DEMON_UnregisterObjectProvider ( DEMON_Session* session, DEMON_ObjectProvider provider, void* userdata );

void DEMON_SendExtendedCommand ( DEMON_Session* session, const char* command, const char* line, const char* peer, bool broadcast );

#define DEMON_PLUGIN_CONNECTED 0
#define DEMON_PLUGIN_DISCONNECTED 1
#define DEMON_PLUGIN_REGISTERED 2
#define DEMON_PLUGIN_UNREGISTERED 3
#define DEMON_PLUGIN_RECEIVED_EXTENDED_COMMAND 4

#ifdef __cplusplus
}
#endif

#endif
