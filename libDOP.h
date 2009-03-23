#ifndef __included_libdop_h
#define __included_libdop_h

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stdint.h>

typedef struct _DOP_Session DOP_Session;

typedef enum _DOP_Transport
{
	DOP_TRANSPORT_HTTP,
	DOP_TRANSPORT_HTTPS,
	DOP_TRANSPORT_TCP,
	DOP_TRANSPORT_ENET
} DOP_Transport;

DOP_Session* DOP_OpenSession ( const char* clientName, DOP_Transport transport, uint16_t port, int maxClients, const void* key, unsigned keyLength );
void DOP_CloseSession ( DOP_Session* session );

void DOP_LoadTrustDB ( DOP_Session* session, const void* db, uint64_t length );
void* DOP_SaveTrustDB ( DOP_Session* session, uint64_t* length ); // this returns a new pointer

const void* DOP_SessionKey ( DOP_Session* session, unsigned* length );
const char* DOP_PeerID ( DOP_Session* session );

void DOP_Connect ( DOP_Session* session, const char* peer, bool trust, bool keep );
void DOP_Disconnect ( DOP_Session* session, const char* peer );

typedef struct _DOP_BandwidthCap
{
	unsigned maxUploadRate;
	unsigned maxDownloadRate;
} DOP_BandwidthCap;

DOP_BandwidthCap DOP_GetBandwidthCap ( DOP_Session* session );
void DOP_SetBandwidthCap ( DOP_Session* session, DOP_BandwidthCap cap );

typedef struct _DOP_Statistics
{
	unsigned uploadRate, downloadRate;
	float sessionRatio;
	unsigned totalUpload, totalDownload;
} DOP_Statistics;

DOP_Statistics DOP_GetStatistics ( DOP_Session* session );

typedef struct _DOP_Object
{
	uint64_t length;
	uint64_t pieceCount; // if left at 0, DOP_RegisterObject will convert to ceil(length / 512)
	const char** pieceHashes; // often left at NULL; if not, must point to an array of SHA1 hashes of pieces.
	void* userdata;
	bool (*providePieceCallback)(struct _DOP_Object* object, void* userdata, uint64_t pieceID, void** buffer, uint64_t* length); // buffer must point to newly malloc'd memory
	bool (*havePieceCallback)(struct _DOP_Object* object, void* userdata, uint64_t pieceID);
	bool (*receivePieceCallback)(struct _DOP_Object* object, void* userdata, uint64_t pieceID, const void* buffer, uint64_t length);
	uint64_t (*pickPieceCallback)(struct _DOP_Object* object, void* userdata); // return DOP_OBJECT_COMPLETE if all pieces are had
	void (*deleteObjectCallback)(struct _DOP_Object* object, void* userdata);
	char hash[49]; // read-only
	bool shouldUpload, shouldDownload;
	bool isPurgeable; // if this is true, can be deleted at will by the object
	// internal
	uint64_t lastUseTime;
} DOP_Object;

#define DOP_OBJECT_COMPLETE (~(uint64_t)0)

const char* DOP_GenerateTiger ( const void* buffer, uint64_t length );
const char* DOP_GenerateTigerFile ( const char* path );

DOP_Object* DOP_NewObject ( const char* hash ); // a completely blank object, except for the hash
DOP_Object* DOP_NewObjectMemoryDownload ( const char* objectID, void* buffer, uint64_t length );
DOP_Object* DOP_NewObjectMemoryUpload ( const void* buffer, uint64_t length );
DOP_Object* DOP_NewObjectFile ( const char* path, const char* objectID, uint64_t length );
DOP_Object* DOP_NewObjectEmpty ();
void DOP_DeleteObject ( DOP_Object* object );

void DOP_RegisterObject ( DOP_Session* session, DOP_Object* object );
void DOP_UnregisterObject ( DOP_Session* session, DOP_Object* object );

void DOP_BindName ( DOP_Session* session, const char* name, DOP_Object* object );
const char* DOP_LookupName ( DOP_Session* session, uint64_t* length );

typedef bool (*DOP_PluginCallback)(DOP_Session* session, void* userdata, const char* peerName, unsigned pluginCommand, const char* key, const void* data);

void DOP_RegisterPlugin ( DOP_Session* session, DOP_PluginCallback callback, void* userdata, const char** handledCommands );
void DOP_UnregisterPlugin ( DOP_Session* session, DOP_PluginCallback callback, void* userdata );

typedef DOP_Object* (*DOP_ObjectProvider)(DOP_Session* session, void* userdata, const char* objectID);

void DOP_RegisterObjectProvider ( DOP_Session* session, DOP_ObjectProvider provider, void* userdata );
void DOP_UnregisterObjectProvider ( DOP_Session* session, DOP_ObjectProvider provider, void* userdata );

void DOP_SendExtendedCommand ( DOP_Session* session, const char* command, const char* line, const char* peer, bool broadcast );

#define DOP_PLUGIN_CONNECTED 0
#define DOP_PLUGIN_DISCONNECTED 1
#define DOP_PLUGIN_REGISTERED 2
#define DOP_PLUGIN_UNREGISTERED 3
#define DOP_PLUGIN_RECEIVED_EXTENDED_COMMAND 4

#ifdef __cplusplus
}
#endif

#endif
