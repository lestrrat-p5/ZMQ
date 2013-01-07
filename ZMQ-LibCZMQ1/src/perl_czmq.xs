#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perl_czmq.h"

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
version()
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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zctx", 0));

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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zsocket", 0));
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

char *
zsocket_type_str( socket )
        PerlLibCZMQ1_zsocket_raw *socket;

int
_zsocket_bind( socket, address )
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *address;
    CODE:
        RETVAL = zsocket_bind( socket, address );
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
           it as int
        */
#ifdef CZMQ_VOID_RETURN_VALUES
        zsocket_connect( socket, address );
        RETVAL = 0;
#else
        RETVAL = zsocket_connect( socket, address );
#endif
    OUTPUT:
        RETVAL

Bool
zsocket_poll( socket, msecs)
        PerlLibCZMQ1_zsocket_raw *socket;
        int msecs;

char *
zstr_recv(socket)
        PerlLibCZMQ1_zsocket_raw *socket;

char *
zstr_recv_nowait(socket)
        PerlLibCZMQ1_zsocket_raw *socket;

int
zstr_send(socket, string)
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *string;

int
zstr_sendm(socket, string)
        PerlLibCZMQ1_zsocket_raw *socket;
        const char *string;

INCLUDE: versioned-xs.inc

PerlLibCZMQ1_zframe *
zframe_new (data, size)
        const void *data;
        size_t      size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zframe", 0));

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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zframe", 0));

PerlLibCZMQ1_zframe *
zframe_recv_nowait(socket)
        PerlLibCZMQ1_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zframe", 0));

int
zframe_send(frame, socket, flags)
        PerlLibCZMQ1_zframe *frame;
        PerlLibCZMQ1_zsocket_raw *socket;
        int flags;
    CODE:
#ifdef CZMQ_VOID_RETURN_VALUES
        zframe_send( &frame, socket, flags );
        RETVAL = 1;
#else
        RETVAL = zframe_send( &frame, socket, flags );
#endif
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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zframe", 0));

char *
zframe_strhex(frame)
        PerlLibCZMQ1_zframe *frame;

char *
zframe_strdup(frame)
        PerlLibCZMQ1_zframe *frame;

Bool
zframe_streq(frame, string)
        PerlLibCZMQ1_zframe *frame;
        char *string;

int
zframe_more(frame)
        PerlLibCZMQ1_zframe *frame;

Bool
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
    CODE:
#ifdef zframe_zero_copy
        RETVAL = zframe_zero_copy(frame);
#else
        PERL_UNUSED_VAR(frame);
        {
            croak("zframe_zero_copy is not available in this version of libczmq (%d.%d.%d)", CZMQ_VERSION_MAJOR, CZMQ_VERSION_MINOR, CZMQ_VERSION_PATCH);
        }
#endif
    OUTPUT:
        RETVAL

PerlLibCZMQ1_zmsg *
zmsg_new()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

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

#ifdef CZMQ_VOID_RETURN_VALUES

void
zmsg_push(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

#else

int
zmsg_push(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

#endif

PerlLibCZMQ1_zframe *
zmsg_pop(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

#ifdef CZMQ_VOID_RETURN_VALUES

void
zmsg_add(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

void
zmsg_pushmem(msg, src, size)
        PerlLibCZMQ1_zmsg *msg;
        const void *src;
        size_t size;

void
zmsg_addmem(msg, src, size)
        PerlLibCZMQ1_zmsg *msg;
        const void *src;
        size_t size;

#else

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

#endif

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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

void
zmsg_remove(msg, frame)
        PerlLibCZMQ1_zmsg *msg;
        PerlLibCZMQ1_zframe *frame;

PerlLibCZMQ1_zframe *
zmsg_first(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

PerlLibCZMQ1_zframe *
zmsg_next(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

PerlLibCZMQ1_zframe *
zmsg_last(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

int
zmsg_save(msg, file)
        PerlLibCZMQ1_zmsg *msg;
        FILE *file;

PerlLibCZMQ1_zmsg *
zmsg_load(msg, file)
        PerlLibCZMQ1_zmsg *msg;
        FILE *file;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

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
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

PerlLibCZMQ1_zmsg *
zmsg_dup(msg)
        PerlLibCZMQ1_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::LibCZMQ1::zmsg", 0));

void
zmsg_dump(msg)
        PerlLibCZMQ1_zmsg *msg;


