#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "xs/perl_czmq.h"

STATIC_INLINE
int
PerlCZMQ_zctx_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlCZMQ_zctx *ctx;
    PERL_UNUSED_VAR(sv);

    ctx = (PerlCZMQ_zctx *) mg->mg_ptr;
    if (ctx != NULL) {
        zctx_destroy(&ctx);
        mg->mg_ptr = NULL;
    }

    return 0;
}

STATIC_INLINE
int
PerlCZMQ_zsocket_mg_free(pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlCZMQ_zsocket *socket;
    PERL_UNUSED_VAR(sv);

    socket = (PerlCZMQ_zsocket *) mg->mg_ptr;
    if (socket != NULL) {
        zsocket_destroy(socket->ctx, socket->socket);
        Safefree(socket);
        mg->mg_ptr = NULL;
    }

    return 0;
}

#include "mg-xs.inc"

MODULE = ZMQ::CZMQ  PACKAGE = ZMQ::CZMQ 

PROTOTYPES: DISABLE

PerlCZMQ_zctx *
zctx_new()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zctx", 0));

void
zctx_destroy( ctx )
        PerlCZMQ_zctx *ctx;
    CODE:
        if ( ctx != NULL ) {
            MAGIC *mg;

            zctx_destroy( &ctx );
            mg = PerlCZMQ_zctx_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

void
zctx_set_iothreads( ctx, iothreads )
        PerlCZMQ_zctx *ctx;
        int            iothreads;

void
zctx_set_linger( ctx, linger )
        PerlCZMQ_zctx *ctx;
        int            linger;

int
zctx_interrupted()
    CODE:
        RETVAL = zctx_interrupted;
    OUTPUT:
        RETVAL

PerlCZMQ_zsocket *
zsocket_new( ctx, type )
        PerlCZMQ_zctx *ctx;
        int type
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zsocket", 0));
        void *socket;
    CODE:
        socket = zsocket_new( ctx, type );
        if (socket == NULL) {
            croak("Failed to allocate socket?");
        }

        Newxz( RETVAL, 1, PerlCZMQ_zsocket );
        RETVAL->socket = socket;
        RETVAL->ctx    = ctx;
    OUTPUT:
        RETVAL
        

void
zsocket_destroy( ctx, socket )
        PerlCZMQ_zctx *ctx;
        PerlCZMQ_zsocket *socket;
    CODE:
        if ( ctx != NULL && socket != NULL ) {
            MAGIC *mg;
            /* hmmm, socket->ctx exists, so maybe we don't need to be passed ctx ... */

            zsocket_destroy( ctx, socket->socket );
            mg = PerlCZMQ_zsocket_mg_find(aTHX_ SvRV(ST(1)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

char *
zsocket_type_str( socket )
        PerlCZMQ_zsocket_raw *socket;

int
_zsocket_bind( socket, address )
        PerlCZMQ_zsocket_raw *socket;
        const char *address;
    CODE:
        RETVAL = zsocket_bind( socket, address );
    OUTPUT:
        RETVAL

int
_zsocket_connect( socket, address )
        PerlCZMQ_zsocket_raw *socket;
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

char *
zstr_recv(socket)
        PerlCZMQ_zsocket_raw *socket;

char *
zstr_recv_nowait(socket)
        PerlCZMQ_zsocket_raw *socket;

int
zstr_send(socket, string)
        PerlCZMQ_zsocket_raw *socket;
        const char *string;

int
zstr_sendm(socket, string)
        PerlCZMQ_zsocket_raw *socket;
        const char *string;

INCLUDE: versioned-xs.inc

PerlCZMQ_zframe *
zframe_new (data, size)
        const void *data;
        size_t      size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zframe", 0));

void
zframe_destroy(frame)
        PerlCZMQ_zframe *frame;
    CODE:
        if ( frame != NULL ) {
            MAGIC *mg;
            zframe_destroy( &frame );
            mg = PerlCZMQ_zframe_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

PerlCZMQ_zframe *
zframe_recv(socket)
        PerlCZMQ_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zframe", 0));

PerlCZMQ_zframe *
zframe_recv_nowait(socket)
        PerlCZMQ_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zframe", 0));

int
zframe_send(frame, socket, flags)
        PerlCZMQ_zframe *frame;
        PerlCZMQ_zsocket_raw *socket;
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
            MAGIC *mg = PerlCZMQ_zframe_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }
    OUTPUT:
        RETVAL


size_t
zframe_size(frame)
        PerlCZMQ_zframe *frame;

byte *
zframe_data(frame)
        PerlCZMQ_zframe *frame;

PerlCZMQ_zframe *
zframe_dup(frame)
        PerlCZMQ_zframe *frame;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zframe", 0));

char *
zframe_strhex(frame)
        PerlCZMQ_zframe *frame;

char *
zframe_strdup(frame)
        PerlCZMQ_zframe *frame;

Bool
zframe_streq(frame, string)
        PerlCZMQ_zframe *frame;
        char *string;

int
zframe_more(frame)
        PerlCZMQ_zframe *frame;

Bool
zframe_eq(self, other)
        PerlCZMQ_zframe *self;
        PerlCZMQ_zframe *other;

void
zframe_print(frame, prefix)
        PerlCZMQ_zframe *frame;
        char *prefix;

void
zframe_reset(frame, data, size)
        PerlCZMQ_zframe *frame;
        const void *data;
        size_t size;

PerlCZMQ_zmsg *
zmsg_new()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

void
zmsg_destroy(msg)
        PerlCZMQ_zmsg *msg;
    CODE:
        if ( msg != NULL ) {
            MAGIC *mg;
            zmsg_destroy( &msg );
            mg = PerlCZMQ_zmsg_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

PerlCZMQ_zmsg *
zmsg_recv(socket)
        PerlCZMQ_zsocket_raw *socket;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

void
zmsg_send(msg, socket)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zsocket_raw *socket;
    CODE:
        zmsg_send( &msg, socket );
        {
            MAGIC *mg;
            mg = PerlCZMQ_zmsg_mg_find(aTHX_ SvRV(ST(0)));
            if (mg) {
                mg->mg_ptr = NULL;
            }
        }

size_t
zmsg_size(msg)
        PerlCZMQ_zmsg *msg;

size_t
zmsg_content_size(msg)
        PerlCZMQ_zmsg *msg;

#ifdef CZMQ_VOID_RETURN_VALUES

void
zmsg_push(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

#else

int
zmsg_push(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

#endif

PerlCZMQ_zframe *
zmsg_pop(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

#ifdef CZMQ_VOID_RETURN_VALUES

void
zmsg_add(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

void
zmsg_pushmem(msg, src, size)
        PerlCZMQ_zmsg *msg;
        const void *src;
        size_t size;

void
zmsg_addmem(msg, src, size)
        PerlCZMQ_zmsg *msg;
        const void *src;
        size_t size;

#else

int
zmsg_add(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

int
zmsg_pushmem(msg, src, size)
        PerlCZMQ_zmsg *msg;
        const void *src;
        size_t size;

int
zmsg_addmem(msg, src, size)
        PerlCZMQ_zmsg *msg;
        const void *src;
        size_t size;

#endif

char *
zmsg_popstr(msg)
        PerlCZMQ_zmsg *msg;

void
zmsg_wrap(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

PerlCZMQ_zframe *
zmsg_unwrap(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

void
zmsg_remove(msg, frame)
        PerlCZMQ_zmsg *msg;
        PerlCZMQ_zframe *frame;

PerlCZMQ_zframe *
zmsg_first(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

PerlCZMQ_zframe *
zmsg_next(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

PerlCZMQ_zframe *
zmsg_last(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

int
zmsg_save(msg, file)
        PerlCZMQ_zmsg *msg;
        FILE *file;

PerlCZMQ_zmsg *
zmsg_load(msg, file)
        PerlCZMQ_zmsg *msg;
        FILE *file;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

size_t
zmsg_encode(msg, sv)
        PerlCZMQ_zmsg *msg;
        SV *sv;
    PREINIT:
        byte *buffer;
    CODE:
        RETVAL = zmsg_encode(msg, &buffer);
        sv_setpv_mg( sv, (char *) buffer );
    OUTPUT:
        RETVAL

PerlCZMQ_zmsg *
zmsg_decode(buffer, size)
        byte *buffer;
        size_t size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));

PerlCZMQ_zmsg *
zmsg_dup(msg)
        PerlCZMQ_zmsg *msg;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpv("ZMQ::CZMQ::zmsg", 0));



