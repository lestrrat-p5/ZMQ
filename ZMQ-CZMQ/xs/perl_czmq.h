
#include "czmq.h"
#include "xshelper.h"

#define PerlCZMQ_zctx zctx_t
#define PerlCZMQ_zsocket_raw void
typedef struct PerlCZMQ_zsocket_wrapper_t {
    zctx_t *ctx;
    void *socket;
} PerlCZMQ_zsocket;
#define PerlCZMQ_zframe zframe_t
#define PerlCZMQ_zmsg zmsg_t

#ifndef PERLCZMQ_TRACE
#define PERLCZMQ_TRACE 0
#endif

#if (PERLCZMQ_TRACE > 0)
#define PerlCZMQ_trace(...) \
    { \
        PerlIO_printf(PerlIO_stderr(), "[perlczmq (%d)] ", PerlProc_getpid() ); \
        PerlIO_printf(PerlIO_stderr(), __VA_ARGS__); \
        PerlIO_printf(PerlIO_stderr(), "\n"); \
    }
#else
#define PerlCZMQ_trace(...)
#endif


