#include "perl_libzmq3.h"
#include "xshelper.h"

#if (PERLZMQ_TRACE > 0)
#define PerlLibzmq3_trace(...) \
    { \
        PerlIO_printf(PerlIO_stderr(), "[perlzmq (%d)] ", PerlProc_getpid() ); \
        PerlIO_printf(PerlIO_stderr(), __VA_ARGS__); \
        PerlIO_printf(PerlIO_stderr(), "\n"); \
    }
#else
#define PerlLibzmq3_trace(...)
#endif

STATIC_INLINE void
PerlLibzmq3_set_bang(pTHX_ int err) {
    SV *errsv = get_sv("!", GV_ADD);
    PerlLibzmq3_trace(" + Set ERRSV ($!) to %d", err);
    sv_setiv(errsv, err);
    sv_setpv(errsv, zmq_strerror(err));
    errno = err;
}

static
SV *
PerlLibzmq3_zmq_getsockopt_int(PerlLibzmq3_Socket *sock, int option) {
    size_t len;
    int    status;
    I32    i32;
    SV     *sv = newSV(0);

    len = sizeof(i32);
    status = zmq_getsockopt(sock->socket, option, &i32, &len);
    if(status == 0) {
        sv = newSViv(i32);
    } else {
        SET_BANG;
    }
    return sv;
}

static
SV *
PerlLibzmq3_zmq_getsockopt_int64(PerlLibzmq3_Socket *sock, int option) {
    size_t  len;
    int     status;
    int64_t i64;
    SV      *sv = newSV(0);

    len = sizeof(i64);
    status = zmq_getsockopt(sock->socket, option, &i64, &len);
    if(status == 0) {
        sv = newSViv(i64);
    } else {
        SET_BANG;
    }
    return sv;
}

static
SV *
PerlLibzmq3_zmq_getsockopt_uint64(PerlLibzmq3_Socket *sock, int option) {
    size_t len;
    int    status;
    uint64_t u64;
    SV *sv = newSV(0);

    len = sizeof(u64);
    status = zmq_getsockopt(sock->socket, option, &u64, &len);
    if(status == 0) {
        sv = newSVuv(u64);
    } else {
        SET_BANG;
    }
    return sv;
}

static
SV *
PerlLibzmq3_zmq_getsockopt_string(PerlLibzmq3_Socket *sock, int option, size_t len) {
    int    status;
    char   *string;
    SV     *sv = newSV(0);

    Newxz(string, len, char);
    status = zmq_getsockopt(sock->socket, option, string, &len);
    if(status == 0) {
        sv = newSVpvn(string, len);
    } else {
        SET_BANG;
    }
    Safefree(string);

    return sv;
}


STATIC_INLINE
int
PerlLibzmq3_zmq_setsockopt_int( PerlLibzmq3_Socket *sock, int option, int val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE
int
PerlLibzmq3_zmq_setsockopt_int64( PerlLibzmq3_Socket *sock, int option, int64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

static
int
PerlLibzmq3_zmq_setsockopt_uint64(PerlLibzmq3_Socket *sock, int option, uint64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(uint64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}
    
static
int
PerlLibzmq3_zmq_setsockopt_string(PerlLibzmq3_Socket *sock, int option, const char *ptr, size_t len) {
    int status;
    status = zmq_setsockopt(sock->socket, option, ptr, len);
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE int
PerlLibzmq3_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    PerlLibzmq3_Message *const src = (PerlLibzmq3_Message *) mg->mg_ptr;
    PerlLibzmq3_Message *dest;

    PerlLibzmq3_trace("Message -> dup");
    PERL_UNUSED_VAR( param );
 
    Newxz( dest, 1, PerlLibzmq3_Message );
    zmq_msg_init( dest );
    zmq_msg_copy ( dest, src );
    mg->mg_ptr = (char *) dest;
    return 0;
}

STATIC_INLINE int
PerlLibzmq3_Message_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibzmq3_Message* const msg = (PerlLibzmq3_Message *) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    PerlLibzmq3_trace( "START mg_free (Message)" );
    if ( msg != NULL ) {
        PerlLibzmq3_trace( " + zmq message %p", msg );
        zmq_msg_close( msg );
        Safefree( msg );
    }
    PerlLibzmq3_trace( "END mg_free (Message)" );
    return 1;
}

STATIC_INLINE MAGIC*
PerlLibzmq3_Message_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    PerlLibzmq3_trace( "mg_find (Message)" );
    PerlLibzmq3_trace( " + SV %p", sv )
    croak("ZMQ::LibZMQ3::Message: Invalid ZMQ::LibZMQ3::Message object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlLibzmq3_Context_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibzmq3_Context* const ctxt = (PerlLibzmq3_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);

    PerlLibzmq3_trace("START mg_free (Context)");
    if (ctxt != NULL) {
#ifdef USE_ITHREADS
        PerlLibzmq3_trace( " + thread enabled. thread %p", aTHX );
        PerlLibzmq3_trace( " + context wrapper %p with zmq context %p", ctxt, ctxt->ctxt );
        if ( ctxt->interp == aTHX ) { /* is where I came from */
            PerlLibzmq3_trace( " + detected mg_free from creating thread %p, cleaning up", aTHX );
            zmq_term( ctxt->ctxt );
            mg->mg_ptr = NULL;
            Safefree(ctxt); /* free the wrapper */
        }
#else
        PerlLibzmq3_trace(" + zmq context %p", ctxt);
        zmq_term( ctxt );
        mg->mg_ptr = NULL;
#endif
    }
    PerlLibzmq3_trace("END mg_free (Context)");
    return 1;
}

STATIC_INLINE MAGIC*
PerlLibzmq3_Context_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZMQ::LibZMQ3::Context: Invalid ZMQ::LibZMQ3::Context object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlLibzmq3_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

STATIC_INLINE int
PerlLibzmq3_Socket_invalidate( PerlLibzmq3_Socket *sock )
{
    SV *ctxt_sv = sock->assoc_ctxt;
    int rv;

    PerlLibzmq3_trace("START socket_invalidate");
    PerlLibzmq3_trace(" + zmq socket %p", sock->socket);
    rv = zmq_close( sock->socket );

    if ( SvOK(ctxt_sv) ) {
        PerlLibzmq3_trace(" + associated context: %p", ctxt_sv);
        SvREFCNT_dec(ctxt_sv);
        sock->assoc_ctxt = NULL;
    }

    Safefree(sock);

    PerlLibzmq3_trace("END socket_invalidate");
    return rv;
}

STATIC_INLINE int
PerlLibzmq3_Socket_mg_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlLibzmq3_Socket* const sock = (PerlLibzmq3_Socket *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    PerlLibzmq3_trace("START mg_free (Socket)");
    if (sock) {
        PerlLibzmq3_Socket_invalidate( sock );
        mg->mg_ptr = NULL;
    }
    PerlLibzmq3_trace("END mg_free (Socket)");
    return 1;
}

STATIC_INLINE int
PerlLibzmq3_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PerlLibzmq3_trace("START mg_dup (Socket)");
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    mg->mg_ptr = NULL;
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    PerlLibzmq3_trace("END mg_dup (Socket)");
    return 0;
}

STATIC_INLINE MAGIC*
PerlLibzmq3_Socket_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZMQ::Socket: Invalid ZMQ::Socket object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE void 
PerlZMQ_free_string(void *data, void *hint) {
    PERL_SET_CONTEXT(hint);
    Safefree( (char *) data );
}

#include "mg-xs.inc"

MODULE = ZMQ::LibZMQ3    PACKAGE = ZMQ::LibZMQ3   PREFIX = PerlLibzmq3_

PROTOTYPES: DISABLED

BOOT:
    {
        PerlLibzmq3_trace( "Booting ZMQ::LibZMQ3" );
    }

int
zmq_errno()

const char *
zmq_strerror(num)
        int num;

void
PerlLibzmq3_zmq_version()
    PREINIT:
        int major, minor, patch;
        I32 gimme;
    PPCODE:
        gimme = GIMME_V;
        if (gimme == G_VOID) {
            /* WTF? you don't want a return value?! */
            XSRETURN(0);
        }

        zmq_version(&major, &minor, &patch);
        if (gimme == G_SCALAR) {
            XPUSHs( sv_2mortal( newSVpvf( "%d.%d.%d", major, minor, patch ) ) );
            XSRETURN(1);
        } else {
            mXPUSHi( major );
            mXPUSHi( minor );
            mXPUSHi( patch );
            XSRETURN(3);
        }

PerlLibzmq3_Context *
PerlLibzmq3_zmq_init( nthreads = 5 )
        int nthreads;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Context", 20 ));
        void *cxt;
    CODE:
        PerlLibzmq3_trace( "START zmq_init" );
        cxt = zmq_init( nthreads );
        if (cxt == NULL) {
            SET_BANG;
            RETVAL = NULL;
        } else {
#ifdef USE_ITHREADS
            PerlLibzmq3_trace( " + threads enabled, aTHX %p", aTHX );
            Newxz( RETVAL, 1, PerlLibzmq3_Context );
            RETVAL->interp = aTHX;
            RETVAL->ctxt   = cxt;
            PerlLibzmq3_trace( " + created context wrapper %p", RETVAL );
            PerlLibzmq3_trace( " + zmq context %p", RETVAL->ctxt );
#else
            PerlLibzmq3_trace( " + non-threaded context");
            RETVAL = cxt;
#endif
        }
        PerlLibzmq3_trace( "END zmq_init");
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_term( context )
        PerlLibzmq3_Context *context;
    CODE:
#ifdef USE_ITHREADS
        RETVAL = zmq_term( context->ctxt );
#else
        RETVAL = zmq_term( context );
#endif
        if (RETVAL != 0) {
            SET_BANG;
        } else {
            {
                /* Cancel the SV's mg attr so to not call zmq_term automatically */
                MAGIC *mg =
                    PerlLibzmq3_Context_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq3_Context_vtbl );
                mg->mg_ptr = NULL;
            }

            /* mark the original SV's _closed flag as true */
            {
                SV *svr = SvRV(ST(0));
                if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                    croak("PANIC: Failed to store closed flag on blessed reference");
                }
            }
        }
    OUTPUT:
        RETVAL

PerlLibzmq3_Message *
PerlLibzmq3_zmq_msg_init()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rc;
    CODE:
        Newxz( RETVAL, 1, PerlLibzmq3_Message );
        rc = zmq_msg_init( RETVAL );
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlLibzmq3_Message *
PerlLibzmq3_zmq_msg_init_size( size )
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rc;
    CODE: 
        Newxz( RETVAL, 1, PerlLibzmq3_Message );
        rc = zmq_msg_init_size(RETVAL, size);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlLibzmq3_Message *
PerlLibzmq3_zmq_msg_init_data( data, size = -1)
        SV *data;
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        STRLEN x_data_len;
        char *sv_data = SvPV(data, x_data_len);
        char *x_data;
        int rc;
    CODE: 
        PerlLibzmq3_trace("START zmq_msg_init_data");
        if (size >= 0) {
            x_data_len = size;
        }
        Newxz( RETVAL, 1, PerlLibzmq3_Message );
        Newxz( x_data, x_data_len, char );
        Copy( sv_data, x_data, x_data_len, char );
        rc = zmq_msg_init_data(RETVAL, x_data, x_data_len, PerlZMQ_free_string, Perl_get_context());
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
        else {
            PerlLibzmq3_trace(" + zmq_msg_init_data created message %p", RETVAL);
        }
        PerlLibzmq3_trace("END zmq_msg_init_data");
    OUTPUT:
        RETVAL

SV *
PerlLibzmq3_zmq_msg_data(message)
        PerlLibzmq3_Message *message;
    CODE:
        PerlLibzmq3_trace( "START zmq_msg_data" );
        PerlLibzmq3_trace( " + message content '%s'", (char *) zmq_msg_data(message) );
        PerlLibzmq3_trace( " + message size '%d'", (int) zmq_msg_size(message) );
        RETVAL = newSV(0);
        sv_setpvn( RETVAL, (char *) zmq_msg_data(message), (STRLEN) zmq_msg_size(message) );
        PerlLibzmq3_trace( "END zmq_msg_data" );
    OUTPUT:
        RETVAL

size_t
PerlLibzmq3_zmq_msg_size(message)
        PerlLibzmq3_Message *message;
    CODE:
        RETVAL = zmq_msg_size(message);
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_msg_close(message)
        PerlLibzmq3_Message *message;
    CODE:
        PerlLibzmq3_trace("START zmq_msg_close");
        RETVAL = zmq_msg_close(message);
        Safefree(message);
        if (RETVAL != 0) {
            SET_BANG;
        }

        {
            MAGIC *mg =
                 PerlLibzmq3_Message_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq3_Message_vtbl );
             mg->mg_ptr = NULL;
        }
        /* mark the original SV's _closed flag as true */
        {
            SV *svr = SvRV(ST(0));
            if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                croak("PANIC: Failed to store closed flag on blessed reference");
            }
        }
        PerlLibzmq3_trace("END zmq_msg_close");
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_msg_move(dest, src)
        PerlLibzmq3_Message *dest;
        PerlLibzmq3_Message *src;
    CODE:
        RETVAL = zmq_msg_move( dest, src );
        if (RETVAL != 0) {
            SET_BANG;
        }
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_msg_copy (dest, src);
        PerlLibzmq3_Message *dest;
        PerlLibzmq3_Message *src;
    CODE:
        RETVAL = zmq_msg_copy( dest, src );
        if (RETVAL != 0) {
            SET_BANG;
        }
    OUTPUT:
        RETVAL

PerlLibzmq3_Socket *
PerlLibzmq3_zmq_socket (ctxt, type)
        PerlLibzmq3_Context *ctxt;
        IV type;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Socket", 19 ));
        void *sock = NULL;
    CODE:
        PerlLibzmq3_trace( "START zmq_socket" );
#ifdef USE_ITHREADS
        PerlLibzmq3_trace( " + context wrapper %p, zmq context %p", ctxt, ctxt->ctxt );
        sock = zmq_socket( ctxt->ctxt, type );
#else
        PerlLibzmq3_trace( " + zmq context %p", ctxt );
        sock = zmq_socket( ctxt, type );
#endif
        if (sock == NULL) {
            RETVAL = NULL;
            SET_BANG;
        } else {
            Newxz( RETVAL, 1, PerlLibzmq3_Socket );
            RETVAL->assoc_ctxt = ST(0);
            RETVAL->socket = sock;
            SvREFCNT_inc(RETVAL->assoc_ctxt);
            PerlLibzmq3_trace( " + created socket %p", RETVAL );
        }
        PerlLibzmq3_trace( "END zmq_socket" );
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_close(socket)
        PerlLibzmq3_Socket *socket;
    CODE:
        RETVAL = PerlLibzmq3_Socket_invalidate( socket );
        /* Cancel the SV's mg attr so to not call socket_invalidate again
           during Socket_mg_free
        */
        {
            MAGIC *mg =
                 PerlLibzmq3_Socket_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq3_Socket_vtbl );
             mg->mg_ptr = NULL;
        }

        /* mark the original SV's _closed flag as true */
        {
            SV *svr = SvRV(ST(0));
            if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                croak("PANIC: Failed to store closed flag on blessed reference");
            }
        }
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_connect(socket, addr)
        PerlLibzmq3_Socket *socket;
        char *addr;
    CODE:
        PerlLibzmq3_trace( "START zmq_connect" );
        PerlLibzmq3_trace( " + socket %p", socket );
        RETVAL = zmq_connect( socket->socket, addr );
        PerlLibzmq3_trace(" + zmq_connect returned with rv '%d'", RETVAL);
        if (RETVAL != 0) {
            SET_BANG;
        }
        PerlLibzmq3_trace( "END zmq_connect" );
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_bind(socket, addr)
        PerlLibzmq3_Socket *socket;
        char *addr;
    CODE:
        PerlLibzmq3_trace( "START zmq_bind" );
        PerlLibzmq3_trace( " + socket %p", socket );
        RETVAL = zmq_bind( socket->socket, addr );
        PerlLibzmq3_trace(" + zmq_bind returned with rv '%d'", RETVAL);
        if (RETVAL != 0) {
            SET_BANG;
        }
        PerlLibzmq3_trace( "END zmq_bind" );
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_recv(socket, buf_sv, len, flags = 0)
        PerlLibzmq3_Socket *socket;
        SV *buf_sv;
        size_t len;
        int flags;
    PREINIT:
        char *buf;
    CODE:
        PerlLibzmq3_trace( "START zmq_recv" );
        Newxz( buf, len, char );

        RETVAL = zmq_recv( socket->socket, buf, len, flags );
        PerlLibzmq3_trace(" + zmq_recv returned with rv '%d'", RETVAL);
        if ( RETVAL == -1 ) {
            SET_BANG;
            Safefree(buf);
        } else {
            sv_setpvn( buf_sv, buf, len );
        }
        PerlLibzmq3_trace( "END zmq_recv" );
    OUTPUT:
        RETVAL
        
PerlLibzmq3_Message *
PerlLibzmq3_zmq_recvmsg(socket, flags = 0)
        PerlLibzmq3_Socket *socket;
        int flags;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rv;
        zmq_msg_t msg;
    CODE:
        PerlLibzmq3_trace( "START zmq_recvmsg" );
        RETVAL = NULL;
        rv = zmq_msg_init(&msg);
        if (rv != 0) {
            SET_BANG;
            PerlLibzmq3_trace("zmq_msg_init failed (%d)", rv);
            XSRETURN_EMPTY;
        }
        rv = zmq_recvmsg(socket->socket, &msg, flags);
        PerlLibzmq3_trace(" + zmq_recvmsg with flags %d", flags);
        PerlLibzmq3_trace(" + zmq_recvmsg returned with rv '%d'", rv);
        if (rv == -1) {
            SET_BANG;
            PerlLibzmq3_trace(" + zmq_recvmsg got bad status, closing temporary message");
            zmq_msg_close(&msg);
        } else {
            PerlLibzmq3_trace(" + message data (%s)", (char *) zmq_msg_data(&msg) );
            PerlLibzmq3_trace(" + message size (%d)", (int) zmq_msg_size(&msg) );
            Newxz(RETVAL, 1, PerlLibzmq3_Message);
            rv = zmq_msg_init(RETVAL);
            if (rv != 0) {
                SET_BANG;
                PerlLibzmq3_trace(" + zmq_msg_init (copy) failed with %d", rv );
                Safefree(RETVAL);
                zmq_msg_close(&msg);
                XSRETURN_EMPTY;
            }

            rv = zmq_msg_copy( RETVAL, &msg );
            if (rv != 0) {
                SET_BANG;
                PerlLibzmq3_trace(" + zmq_msg_copy failed with %d", rv );
                Safefree(RETVAL);
                zmq_msg_close(&msg);
                XSRETURN_EMPTY;
            }
            PerlLibzmq3_trace(" + zmq_recvmsg created message %p", RETVAL );
            zmq_msg_close(&msg);
        }
        PerlLibzmq3_trace( "END zmq_recvmsg" );
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_send(socket, message, size = -1, flags = 0)
        PerlLibzmq3_Socket *socket;
        SV *message;
        int size;
        int flags;
    PREINIT:
        char *message_buf;
        STRLEN usize;
    CODE:
        PerlLibzmq3_trace( "START zmq_send" );
        if (! SvOK(message))
            croak("ZMQ::LibZMQ3::zmq_send(): NULL message passed");

        message_buf = SvPV( message, usize );
        if ( size != -1 && (STRLEN)size < usize )
            usize = (STRLEN)size;

        PerlLibzmq3_trace( " + buffer '%s' (%zu)", message_buf, usize );
        PerlLibzmq3_trace( " + flags %d", flags);
        RETVAL = zmq_send( socket->socket, message_buf, usize, flags );
        PerlLibzmq3_trace( " + zmq_send returned with rv '%d'", RETVAL );
        if ( RETVAL == -1 ) {
            PerlLibzmq3_trace( " ! zmq_send error %s", zmq_strerror( zmq_errno() ) );
            SET_BANG;
        }
        PerlLibzmq3_trace( "END zmq_send" );
    OUTPUT:
        RETVAL

int
PerlLibzmq3__zmq_sendmsg(socket, message, flags = 0)
        PerlLibzmq3_Socket *socket;
        PerlLibzmq3_Message *message;
        int flags;
    CODE:
        PerlLibzmq3_trace( "START zmq_sendmsg" );
        RETVAL = zmq_sendmsg(socket->socket, message, flags);
        PerlLibzmq3_trace( " + zmq_sendmsg returned with rv '%d'", RETVAL );
        if ( RETVAL == -1 ) {
            PerlLibzmq3_trace( " ! zmq_sendmsg error %s", zmq_strerror( zmq_errno() ) );
            SET_BANG;
        }
        PerlLibzmq3_trace( "END zmq_sendmsg" );
    OUTPUT:
        RETVAL

SV *
PerlLibzmq3_zmq_getsockopt_int(sock, option)
        PerlLibzmq3_Socket *sock;
        int option;

SV *
PerlLibzmq3_zmq_getsockopt_int64(sock, option)
        PerlLibzmq3_Socket *sock;
        int option;

SV *
PerlLibzmq3_zmq_getsockopt_uint64(sock, option)
        PerlLibzmq3_Socket *sock;
        int option;

SV *
PerlLibzmq3_zmq_getsockopt_string(sock, option, len = 1024)
        PerlLibzmq3_Socket *sock;
        int option;
        size_t len;

int
PerlLibzmq3_zmq_setsockopt_int(sock, option, val)
        PerlLibzmq3_Socket *sock;
        int option;
        int val;

int
PerlLibzmq3_zmq_setsockopt_int64(sock, option, val)
        PerlLibzmq3_Socket *sock;
        int option;
        int64_t val;

int
PerlLibzmq3_zmq_setsockopt_uint64(sock, option, val)
        PerlLibzmq3_Socket *sock;
        int option;
        uint64_t val;

int
PerlLibzmq3_zmq_setsockopt_string(sock, option, value)
        PerlLibzmq3_Socket *sock;
        int option;
        SV *value;
    PREINIT:
        size_t len;
        const char *string;
    CODE:
        string = SvPV( value, len );
        RETVAL = PerlLibzmq3_zmq_setsockopt_string(sock, option, string, len);
    OUTPUT:
        RETVAL

int
PerlLibzmq3_zmq_poll( list, timeout = 0 )
        AV *list;
        long timeout;
    PREINIT:
        I32 list_len;
        zmq_pollitem_t *pollitems;
        CV **callbacks;
        int i;
        int rv;
        int eventfired;
    PPCODE:
        PerlLibzmq3_trace( "START zmq_poll" );

        list_len = av_len( list ) + 1;
        if (list_len <= 0) {
            XSRETURN(0);
        }

        Newxz( pollitems, list_len, zmq_pollitem_t);
        Newxz( callbacks, list_len, CV *);

        /* list should be a list of hashrefs fd, events, and callbacks */
        for (i = 0; i < list_len; i++) {
            SV **svr = av_fetch( list, i, 0 );
            HV  *elm;

            PerlLibzmq3_trace( " + processing element %d", i );
            if (svr == NULL || ! SvOK(*svr) || ! SvROK(*svr) || SvTYPE(SvRV(*svr)) != SVt_PVHV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid value on index %d", i);
            }
            elm = (HV *) SvRV(*svr);

            callbacks[i] = NULL;
            pollitems[i].revents = 0;
            pollitems[i].events  = 0;
            pollitems[i].fd      = 0;
            pollitems[i].socket  = NULL;

            svr = hv_fetch( elm, "socket", 6, NULL );
            if (svr != NULL) {
                MAGIC *mg;
                if (! SvOK(*svr) || !sv_isobject( *svr) || ! sv_isa(*svr, "ZMQ::LibZMQ3::Socket")) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'socket' given for index %d", i);
                }
                mg = PerlLibzmq3_Socket_mg_find( aTHX_ SvRV(*svr), &PerlLibzmq3_Socket_vtbl );
                pollitems[i].socket = ((PerlLibzmq3_Socket *) mg->mg_ptr)->socket;
                PerlLibzmq3_trace( " + via pollitem[%d].socket = %p", i, pollitems[i].socket );
            } else {
                svr = hv_fetch( elm, "fd", 2, NULL );
                if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'fd' given for index %d", i);
                }
                pollitems[i].fd = SvIV( *svr );
                PerlLibzmq3_trace( " + via pollitem[%d].fd = %d", i, pollitems[i].fd );
            }

            svr = hv_fetch( elm, "events", 6, NULL );
            if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'events' given for index %d", i);
            }
            pollitems[i].events = SvIV( *svr );
            PerlLibzmq3_trace( " + going to poll events %d", pollitems[i].events );

            svr = hv_fetch( elm, "callback", 8, NULL );
            if (svr == NULL || ! SvOK(*svr) || ! SvROK(*svr) || SvTYPE(SvRV(*svr)) != SVt_PVCV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'callback' given for index %d", i);
            }
            callbacks[i] = (CV *) SvRV( *svr );
        }

        /* now call zmq_poll */
        rv = zmq_poll( pollitems, list_len, timeout );
        SET_BANG;
        PerlLibzmq3_trace( " + zmq_poll returned with rv '%d'", RETVAL );

        if (rv != -1 ) {
            for ( i = 0; i < list_len; i++ ) {
                PerlLibzmq3_trace( " + checking events for %d", i );
                eventfired = 
                    (pollitems[i].revents & pollitems[i].events) ? 1 : 0;
                if (GIMME_V == G_ARRAY) {
                    mXPUSHi(eventfired);
                }

                if (eventfired) {
                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    PUTBACK;

                    call_sv( (SV*)callbacks[i], G_SCALAR );
                    SPAGAIN;

                    PUTBACK;
                    FREETMPS;
                    LEAVE;
                }
            }
        }

        if (GIMME_V == G_SCALAR) {
            mXPUSHi(rv);
        }
        Safefree(pollitems);
        Safefree(callbacks);
        PerlLibzmq3_trace( "END zmq_poll" );

int
PerlLibzmq3_zmq_device( device, insocket, outsocket )
        int device;
        PerlLibzmq3_Socket *insocket;
        PerlLibzmq3_Socket *outsocket;
    CODE:
#ifdef zmq_device
        RETVAL = zmq_device( device, insocket->socket, outsocket->socket );
#else
        PERL_UNUSED_VAR(device);
        {
            int major, minor, patch;
            zmq_version(&major, &minor, &patch);
            croak("zmq_device is not available in this version of libzmq (%d.%d.%d)", major, minor, patch );
        }
#endif
    OUTPUT:
        RETVAL

