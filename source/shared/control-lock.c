#ifdef WIN32
#include <windows.h>
#else
#include <time.h>
#endif

// value 0 indicates normal operation
// value 1 indicates control thread is waiting for sync
// value 2 indicates control thread is working

#ifdef __MACH__
// taken from Apple's source: dyld/lock.c
volatile mach_port_t cached_thread = MACH_PORT_NULL;
volatile vm_address_t cached_stack = 0;
static mach_port_t ctrl_mach_thread_self(void)
{
    mach_port_t my_thread;
    vm_address_t stack_addr;

	my_thread = MACH_PORT_NULL;
	stack_addr = (vm_address_t)trunc_page((vm_address_t)&my_thread);

	while(try_to_get_lock(global_lock) == FALSE){
	    yield(1);
	}
	if(cached_stack == stack_addr){
	    my_thread = cached_thread;
	}
	else{
	    if(cached_thread != MACH_PORT_NULL)
#ifdef __MACH30__
	    	(void)mach_port_deallocate(mach_task_self(), cached_thread);
#else
	    	(void)port_deallocate(mach_task_self(), cached_thread);
#endif
	    my_thread = mach_thread_self();
	    cached_thread = my_thread;
	    cached_stack = stack_addr;
	}
	clear_lock(global_lock);
	return(my_thread);
}
#endif

static void yield ()
{
#ifdef WIN32
	Sleep(0);
#else
	struct timespec ts;
	ts.tv_sec = 0;
	tv.tv_nsec = 100;
	nanosleep(&ts, NULL);
#endif
}

#ifdef __MACH__
void WorkThreadSync ( ControlLock* lock )
{
	if (lock->workerThread == MACH_PORT_NULL)
		lock->workerThread = ctrl_mach_thread_self();
	while (lock->lock == 1)
	{
		lock->lock = 2;
		do 
		{
			thread_switch(lock->controlThread, SWITCH_OPTION_NONE, 0);
		} while (lock->lock == 2);
		thread_switch(lock->controlThread, SWITCH_OPTION_NONE, 0);
		// we switch again so that if the next thing in the control thread is another call up here it's not blocking long waiting for the next sync point
	}
}

void ControlThreadLock ( ControlLock* lock )
{
	while (lock->lock != 0) yield();
	lock->controlThread = ctrl_mach_thread_self();
	lock->lock = 1;
	while (lock->lock == 1)
	{
		thread_switch(lock->workerThread, SWITCH_OPTION_NONE, 0);
	}
}

void ControlThreadUnlock ( ControlLock* lock )
{
	lock->lock = 0;
}
#else
void WorkThreadSync ( ControlLock* lock )
{
	if (*lock == 1)
		*lock = 2;
	while (*lock == 2)
		yield();
}

void ControlThreadLock ( ControlLock* lock )
{
	*lock = 1;
	while (*lock == 1) yield();
}

void ControlThreadUnlock ( ControlLock* lock )
{
	*lock = 0;
}
#endif
