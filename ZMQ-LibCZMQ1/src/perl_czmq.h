
#include "czmq.h"
#include "xshelper.h"

#define PerlLibCZMQ1_zctx zctx_t
#define PerlLibCZMQ1_zsocket_raw void
typedef struct PerlLibCZMQ1_zsocket_wrapper_t {
    zctx_t *ctx;
    void *socket;
} PerlLibCZMQ1_zsocket;
#define PerlLibCZMQ1_zframe zframe_t
#define PerlLibCZMQ1_zmsg zmsg_t

#ifndef PERLCZMQ_TRACE
#define PERLCZMQ_TRACE 0
#endif

#if (PERLCZMQ_TRACE > 0)
#define PerlLibCZMQ1_trace(...) \
    { \
        PerlIO_printf(PerlIO_stderr(), "[perlczmq (%d)] ", PerlProc_getpid() ); \
        PerlIO_printf(PerlIO_stderr(), __VA_ARGS__); \
        PerlIO_printf(PerlIO_stderr(), "\n"); \
    }
#else
#define PerlLibCZMQ1_trace(...)
#endif


