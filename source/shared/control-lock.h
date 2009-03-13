#ifndef __included_control_lock_h
#define __included_control_lock_h

#include <stdbool.h>
#ifdef __MACH__
#include <mach/mach.h>
#endif

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef __MACH__
typedef struct _ControlLock
{
	volatile long lock;
	mach_port_t workerThread;
	mach_port_t controlThread;
} ControlLock;
#define CONTROL_LOCK_INIT { 0, MACH_PORT_NULL, MACH_PORT_NULL }
#else
typedef volatile long ControlLock;
#define CONTROL_LOCK_INIT 0
#endif

void WorkThreadSync ( ControlLock* lock );
void ControlThreadLock ( ControlLock* lock );
void ControlThreadUnlock ( ControlLock* lock );

#ifdef __cplusplus
}
#endif

#endif