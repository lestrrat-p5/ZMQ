#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perl_czmq.h"

#define PerlLibczmq1_function_unavailable(name) \
    { \
        int major, minor, patch; \
        zmq_version(&major, &minor, &patch); \
        croak("%s is not available in this version of libczmq (%d.%d.%d)", name, \
                CZMQ_VERSION_MAJOR, \
                CZMQ_VERSION_MINOR, \
                CZMQ_VERSION_PATCH \
        ); \
    }

STATIC_INLINE
int
PerlLibCZMQ1_zctx_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibCZMQ1_zctx *ctx;
    PERL_UNUSED_VAR(sv);

    ctx = (PerlLibCZMQ1_zctx *) mg->mg_ptr;
    if (ctx != NULL) {
        zctx_destroy(&ctx);
        mg->mg_ptr = NULL;
    }

    return 0;
}

STATIC_INLINE
int
PerlLibCZMQ1_zsocket_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibCZMQ1_zsocket *socket;
    PERL_UNUSED_VAR(sv);

    socket = (PerlLibCZMQ1_zsocket *) mg->mg_ptr;
    if (socket != NULL) {
        zsocket_destroy(socket->ctx, socket->socket);
        Safefree(socket);
        mg->mg_ptr = NULL;
    }

    return 0;
}

STATIC_INLINE
int
PerlLibCZMQ1_zframe_mg_free(pTHX_ SV * const sv, MAGIC *const mg) {
    PerlLibCZMQ1_zframe *frame;
    PERL_UNUSED_VAR(sv);

    frame = (PerlLibCZMQ1_zframe *) mg->mg_ptr;
    if (frame) {
        zframe_destroy(&frame);
        mg->mg_ptr = NULL;
    }

    return 0;
}
    
STATIC_INLINE
int
PerlLibCZMQ1_zmsg_mg_free(pTHX_ SV * const sv, MAGIC *const mg) {
    PerlLibCZMQ1_zmsg *msg;
    PERL_UNUSED_VAR(sv);

    msg = (PerlLibCZMQ1_zmsg *) mg->mg_ptr;
    if (msg) {
        zmsg_destroy(&msg);
        mg->mg_ptr = NULL;
    }

    return 0;
}
    

#include "mg-xs.inc"

MODULE = ZMQ::LibCZMQ1  PACKAGE = ZMQ::LibCZMQ1 

PROTOTYPES: DISABLE

void
zmq_version()
    PREINIT:
        I32 gimme;
    PPCODE:
        gimme = GIMME_V;
        if (gimme == G_VOID) {
            XSRETURN(0);
        }

        if (gimme == G_SCALAR) {
            XPUSHs(sv_2mortal(newSVpvf(
                "%d.%d.%d",
                ZMQ_VERSION_MAJOR,
                ZMQ_VERSION_MINOR,
                ZMQ_VERSION_PATCH
            )));
            XSRETURN(1);
        } else {
            mXPUSHi(ZMQ_VERSION_MAJOR);
            mXPUSHi(ZMQ_VERSION_MINOR);
            mXPUSHi(ZMQ_VERSION_PATCH);
            XSRETURN(3);
        }

void
czmq_version()
    PREINIT:
        I32 gimme;
    PPCODE:
        gimme = GIMME_V;
        if (gimme == G_VOID) {
            XSRETURN(0);
        }

        if (gimme == G_SCALAR) {
            XPUSHs(sv_2mortal(newSVpvf(
                "%d.%d.%d",
                CZMQ_VERSION_MAJOR,
                CZMQ_VERSION_MINOR,
                CZMQ_VERSION_PATCH
            )));
            XSRETURN(1);
        } else {
            mXPUSHi(CZMQ_VERSION_MAJOR);
            mXPUSHi(CZMQ_VERSION_MINOR);
            mXPUSHi(CZMQ_VERSION_PATCH);
            XSRETURN(3);
        }

PerlLibCZMQ1_zctx *
zctx_new()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zctx", 0));

void
zctx_destroy( ctx )
        PerlLibCZMQ1_zctx *ctx;
    CODE:
        if ( ctx != NULL ) {
            MAGIC *mg;

            zctx_destroy( &ctx );
            mg = PerlLibCZMQ1_zctx_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

void
zctx_set_iothreads( ctx, iothreads )
        PerlLibCZMQ1_zctx *ctx;
        int            iothreads;

void
zctx_set_linger( ctx, linger )
        PerlLibCZMQ1_zctx *ctx;
        int            linger;

int
zctx_interrupted()
    CODE:
        RETVAL = zctx_interrupted;
    OUTPUT:
        RETVAL

PerlLibCZMQ1_zsocket *
zsocket_new( ctx, type )
        PerlLibCZMQ1_zctx *ctx;
        int type
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zsocket", 0));
        void *socket;
    CODE:
        socket = zsocket_new( ctx, type );
        if (socket == NULL) {
            croak("Failed to allocate socket?");
        }

        Newxz( RETVAL, 1, PerlLibCZMQ1_zsocket );
        RETVAL->socket = socket;
        RETVAL->ctx    = ctx;
    OUTPUT:
        RETVAL
        

void
zsocket_destroy( ctx, socket )
        PerlLibCZMQ1_zctx *ctx;
        PerlLibCZMQ1_zsocket *socket;
    CODE:
        if ( ctx != NULL && socket != NULL ) {
            MAGIC *mg;
            /* hmmm, socket->ctx exists, so maybe we don't need to be passed ctx ... */

            zsocket_destroy( ctx, socket->socket );
            mg = PerlLibCZMQ1_zsocket_mg_find(aTHX_ SvRV(ST(1)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

const char *
zsocket_type_str( socket )
        PerlLibCZMQ1_zsocket_raw *socket;

int
_zsocket_bind( socket, address )
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *address;
    CODE:
        RETVAL = zsocket_bind( socket, "%s", address );
    OUTPUT:
        RETVAL

int
_zsocket_connect( socket, address )
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *address;
    CODE:
        /* doing SV -> va_arg conversion for sprintf-like formatting
           is such a pain, we're not going to allow it 
        */
        /* XXX czmq 1.1.0 defines this as void, where as 1.2.0 declares
           it as int. We're not supporting old czmq
        */
        RETVAL = zsocket_connect( socket, "%s", address );
    OUTPUT:
        RETVAL

bool
zsocket_poll( socket, msecs)
        PerlLibCZMQ1_zsocket_raw *socket;
        int msecs;

int  zsocket_affinity (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_backlog (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_fd (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_linger (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int
zsocket_maxmsgsize (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_MAXMSGSIZE
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_maxmsgsize");
#else
        RETVAL = zsocket_maxmsgsize(socket);
#endif
    OUTPUT:
        RETVAL

int  zsocket_rate (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_rcvbuf (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int
zsocket_rcvhwm (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_RCVHWM
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_rcvhwm");
#else
        RETVAL = zsocket_rcvhwm(socket);
#endif
    OUTPUT:
        RETVAL

int  zsocket_rcvmore (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_reconnect_ivl (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_reconnect_ivl_max (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_recovery_ivl (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_sndbuf (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int
zsocket_sndhwm (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_SNDHWM
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_sndhwm");
#else
        RETVAL = zsocket_sndhwm(socket);
#endif
    OUTPUT:
        RETVAL

int  zsocket_type (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int  zsocket_events (socket)
        PerlLibCZMQ1_zsocket_raw *socket;

void
zsocket_set_sndhwm (socket, sndhwm)
        PerlLibCZMQ1_zsocket_raw *socket;
        int sndhwm;
    CODE:
#ifndef HAS_ZSOCKET_SET_SNDHWM
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(sndhwm);
        PerlLibczmq1_function_unavailable("zsocket_set_sndhwm");
#else
        zsocket_set_sndhwm(socket, sndhwm);
#endif

void
zsocket_set_rcvhwm (socket, rcvhwm)
        PerlLibCZMQ1_zsocket_raw *socket;
        int rcvhwm;
    CODE:
#ifndef HAS_ZSOCKET_SET_RCVHWM
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(rcvhwm);
        PerlLibczmq1_function_unavailable("zsocket_set_rcvhwm");
#else
        zsocket_set_rcvhwm(socket, rcvhwm);
#endif

void zsocket_set_affinity (socket, affinity)
        PerlLibCZMQ1_zsocket_raw *socket;
        int affinity;

void zsocket_set_backlog (socket, backlog)
        PerlLibCZMQ1_zsocket_raw *socket;
        int backlog;

void zsocket_set_identity (socket, identity)
        PerlLibCZMQ1_zsocket_raw *socket;
        char * identity;

void zsocket_set_rate (socket, rate)
        PerlLibCZMQ1_zsocket_raw *socket;
        int rate;

void zsocket_set_recovery_ivl (socket, recovery_ivl)
        PerlLibCZMQ1_zsocket_raw *socket;
        int recovery_ivl;

void zsocket_set_sndbuf (socket, sndbuf)
        PerlLibCZMQ1_zsocket_raw *socket;
        int sndbuf;

void zsocket_set_rcvbuf (socket, rcvbuf)
        PerlLibCZMQ1_zsocket_raw *socket;
        int rcvbuf;

void zsocket_set_linger (socket, linger)
        PerlLibCZMQ1_zsocket_raw *socket;
        int linger;

void zsocket_set_reconnect_ivl (socket, reconnect_ivl)
        PerlLibCZMQ1_zsocket_raw *socket;
        int reconnect_ivl;

void zsocket_set_reconnect_ivl_max (socket, reconnect_ivl_max)
        PerlLibCZMQ1_zsocket_raw *socket;
        int reconnect_ivl_max;

void
zsocket_set_maxmsgsize (socket, maxmsgsize)
        PerlLibCZMQ1_zsocket_raw *socket;
        int maxmsgsize;
    CODE:
#ifndef HAS_ZSOCKET_SET_MAXMSGSIZE
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(maxmsgsize);
        PerlLibczmq1_function_unavailable("zsocket_set_maxmsgsize");
#else
        zsocket_set_maxmsgsize(socket, maxmsgsize);
#endif

void zsocket_set_subscribe (socket, subscribe)
        PerlLibCZMQ1_zsocket_raw *socket;
        char * subscribe;

void zsocket_set_unsubscribe (socket, unsubscribe)
        PerlLibCZMQ1_zsocket_raw *socket;
        char * unsubscribe;

void zsocket_set_hwm (socket, hwm)
        PerlLibCZMQ1_zsocket_raw *socket;
        int hwm;

void
zsocket_set_recovery_ivl_msec (socket, recovery_ivl_msec)
        PerlLibCZMQ1_zsocket_raw *socket;
        int recovery_ivl_msec;
    CODE:
#ifndef HAS_ZSOCKET_SET_RECOVERY_IVL_MSEC
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(recovery_ivl_msec);
        PerlLibczmq1_function_unavailable("zsocket_set_recovery_ivl_msec");
#else
        zsocket_set_recovery_ivl_msec(socket, recovery_ivl_msec);
#endif

int
zsocket_swap (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_SWAP
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_swap");
#else
        RETVAL = zsocket_swap(socket);
#endif
    OUTPUT:
        RETVAL

int
zsocket_mcast_loop (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_MCAST_LOOP
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_mcast_loop");
#else
        RETVAL = zsocket_mcast_loop(socket);
#endif
    OUTPUT:
        RETVAL

int
zsocket_hwm (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_HWM
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_hwm");
#else
        RETVAL = zsocket_hwm(socket);
#endif
    OUTPUT:
        RETVAL

void
zsocket_set_mcast_loop (socket, mcast_loop)
        PerlLibCZMQ1_zsocket_raw *socket;
        int mcast_loop;
    CODE:
#ifndef HAS_ZSOCKET_SET_MCAST_LOOP
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(mcast_loop);
        PerlLibczmq1_function_unavailable("zsocket_set_mcast_loop");
#else
        zsocket_set_mcast_loop(socket, mcast_loop);
#endif

void
zsocket_set_swap (socket, swap)
        PerlLibCZMQ1_zsocket_raw *socket;
        int swap;
    CODE:
#ifndef HAS_ZSOCKET_SET_SWAP
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(swap);
        PerlLibczmq1_function_unavailable("zsocket_set_swap");
#else
        zsocket_set_swap(socket, swap);
#endif

int
zsocket_recovery_ivl_msec (socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
#ifndef HAS_ZSOCKET_RECOVERY_IVL_MSEC
        PERL_UNUSED_VAR(socket);
        PerlLibczmq1_function_unavailable("zsocket_recovery_ivl_msec");
#else
        RETVAL = zsocket_recovery_ivl_msec(socket);
#endif
    OUTPUT:
        RETVAL

char *
zstr_recv(socket)
        PerlLibCZMQ1_zsocket_raw *socket;

char *
zstr_recv_nowait(socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int
_zstr_send(socket, string)
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *string;
    CODE:
        RETVAL = zstr_send(socket, string);
    OUTPUT:
        RETVAL

int
zstr_sendm(socket, string)
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *string;

PerlLibCZMQ1_zframe *
zframe_new (data, size)
        const void *data;
        size_t      size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zframe", 0));

void
zframe_destroy(frame)
        PerlLibCZMQ1_zframe *frame;
    CODE:
        if ( frame != NULL ) {
            MAGIC *mg;
            zframe_destroy( &frame );
            mg = PerlLibCZMQ1_zframe_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

PerlLibCZMQ1_zframe *
zframe_recv(socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zframe", 0));

PerlLibCZMQ1_zframe *
zframe_recv_nowait(socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zframe", 0));

int
zframe_send(frame, socket, flags = 0)
        PerlLibCZMQ1_zframe *frame;
        PerlLibCZMQ1_zsocket_raw *socket;
        int flags;
    CODE:
        RETVAL = zframe_send( &frame, socket, flags );
        /* frame should be destroyed now... */
        if (RETVAL == 0) {
            MAGIC *mg = PerlLibCZMQ1_zframe_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }
    OUTPUT:
        RETVAL


size_t
zframe_size(frame)
        PerlLibCZMQ1_zframe *frame;

byte *
zframe_data(frame)
        PerlLibCZMQ1_zframe *frame;

PerlLibCZMQ1_zframe *
zframe_dup(frame)
        PerlLibCZMQ1_zframe *frame;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zframe", 0));

char *
zframe_strhex(frame)
        PerlLibCZMQ1_zframe *frame;

char *
zframe_strdup(frame)
        PerlLibCZMQ1_zframe *frame;

bool
zframe_streq(frame, string)
        PerlLibCZMQ1_zframe *frame;
        char *string;

int
zframe_more(frame)
        PerlLibCZMQ1_zframe *frame;

bool
zframe_eq(self, other)
        PerlLibCZMQ1_zframe *self;
        PerlLibCZMQ1_zframe *other;

void
zframe_print(frame, prefix)
        PerlLibCZMQ1_zframe *frame;
        char *prefix;

void
zframe_reset(frame, data, size)
        PerlLibCZMQ1_zframe *frame;
        const void *data;
        size_t size;

int
zframe_zero_copy(frame)
        PerlLibCZMQ1_zframe *frame;

PerlLibCZMQ1_zmsg *
zmsg_new()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

void
zmsg_destroy(msg)
        PerlLibCZMQ1_zmsg *msg;
    CODE:
        if ( msg != NULL ) {
            MAGIC *mg;
            zmsg_destroy( &msg );
            mg = PerlLibCZMQ1_zmsg_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

PerlLibCZMQ1_zmsg *
zmsg_recv(socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

void
zmsg_send(msg, socket)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zsocket_raw *socket;
    CODE:
        zmsg_send( &msg, socket );
        {
            MAGIC *mg;
            mg = PerlLibCZMQ1_zmsg_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

size_t
zmsg_size(msg)
        PerlLibCZMQ1_zmsg *msg;

size_t
zmsg_content_size(msg)
        PerlLibCZMQ1_zmsg *msg;

int
zmsg_push(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

PerlLibCZMQ1_zframe *
zmsg_pop(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

int
zmsg_add(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

int
zmsg_pushmem(msg, src, size)
        PerlLibCZMQ1_zmsg *msg;
        const void *src;
        size_t size;

int
zmsg_addmem(msg, src, size)
        PerlLibCZMQ1_zmsg *msg;
        const void *src;
        size_t size;

char *
zmsg_popstr(msg)
        PerlLibCZMQ1_zmsg *msg;

void
zmsg_wrap(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;
    PREINIT:
        MAGIC *mg;
    CODE:
        zmsg_wrap(msg, frame);
        /* memory ownership is now on zmq side. */

        mg = PerlLibCZMQ1_zframe_mg_find(aTHX_ SvRV(ST(1)));
        if (mg) {
            mg->mg_ptr = NULL;
        }

PerlLibCZMQ1_zframe *
zmsg_unwrap(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

void
zmsg_remove(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

PerlLibCZMQ1_zframe *
zmsg_first(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

PerlLibCZMQ1_zframe *
zmsg_next(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

PerlLibCZMQ1_zframe *
zmsg_last(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

int
zmsg_save(msg, file)
        PerlLibCZMQ1_zmsg *msg;
        FILE *file;

PerlLibCZMQ1_zmsg *
zmsg_load(msg, file)
        PerlLibCZMQ1_zmsg *msg;
        FILE *file;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

size_t
zmsg_encode(msg, sv)
        PerlLibCZMQ1_zmsg *msg;
        SV *sv;
    PREINIT:
        byte *buffer;
    CODE:
        RETVAL = zmsg_encode(msg, &buffer);
        sv_setpv_mg( sv, (char *) buffer );
    OUTPUT:
        RETVAL

PerlLibCZMQ1_zmsg *
zmsg_decode(buffer, size)
        byte *buffer;
        size_t size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

PerlLibCZMQ1_zmsg *
zmsg_dup(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::Zmsg", 0));

void
zmsg_dump(msg)
        PerlLibCZMQ1_zmsg *msg;


