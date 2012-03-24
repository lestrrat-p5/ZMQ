#include "perl_libzmq2.h"
#include "xshelper.h"

#if (PERLZMQ_TRACE > 0)
#define PerlLibzmq2_trace(...) \
    { \
        PerlIO_printf(PerlIO_stderr(), "[perlzmq] "); \
        PerlIO_printf(PerlIO_stderr(), __VA_ARGS__); \
        PerlIO_printf(PerlIO_stderr(), "\n"); \
    }
#else
#define PerlLibzmq2_trace(...)
#endif

STATIC_INLINE void
PerlLibzmq2_set_bang(pTHX_ int err) {
    SV *errsv = get_sv("!", GV_ADD);
    PerlLibzmq2_trace("Set ERRSV ($!) to %d", err);
    sv_setiv(errsv, err);
}

static
SV *
PerlLibzmq2_zmq_getsockopt_int(PerlLibzmq2_Socket *sock, int option) {
    size_t len;
    int    status;
    I32    i32;
    SV     *sv;

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
PerlLibzmq2_zmq_getsockopt_int64(PerlLibzmq2_Socket *sock, int option) {
    size_t  len;
    int     status;
    int64_t i64;
    SV      *sv;

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
PerlLibzmq2_zmq_getsockopt_uint64(PerlLibzmq2_Socket *sock, int option) {
    size_t len;
    int    status;
    uint64_t u64;
    SV *sv;

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
PerlLibzmq2_zmq_getsockopt_string(PerlLibzmq2_Socket *sock, int option, size_t len) {
    int    status;
    char   *string;
    SV     *sv;

    Newxz(string, len, char);
    status = zmq_getsockopt(sock->socket, option, &string, &len);
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
PerlLibzmq2_zmq_setsockopt_int( PerlLibzmq2_Socket *sock, int option, int val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE
int
PerlLibzmq2_zmq_setsockopt_int64( PerlLibzmq2_Socket *sock, int option, int64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

static
int
PerlLibzmq2_zmq_setsockopt_uint64(PerlLibzmq2_Socket *sock, int option, uint64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(uint64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}
    
static
int
PerlLibzmq2_zmq_setsockopt_string(PerlLibzmq2_Socket *sock, int option, const char *ptr, size_t len) {
    int status;
    status = zmq_setsockopt(sock->socket, option, ptr, len);
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE int
PerlLibzmq2_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    PerlLibzmq2_Message *const src = (PerlLibzmq2_Message *) mg->mg_ptr;
    PerlLibzmq2_Message *dest;

    PerlLibzmq2_trace("Message -> dup");
    PERL_UNUSED_VAR( param );
 
    Newxz( dest, 1, PerlLibzmq2_Message );
    zmq_msg_init( dest );
    zmq_msg_copy ( dest, src );
    mg->mg_ptr = (char *) dest;
    return 0;
}

STATIC_INLINE int
PerlLibzmq2_Message_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibzmq2_Message* const msg = (PerlLibzmq2_Message *) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    PerlLibzmq2_trace( "START mg_free (Message)" );
    if ( msg != NULL ) {
        PerlLibzmq2_trace( " + zmq message %p", msg );
        zmq_msg_close( msg );
        Safefree( msg );
    }
    PerlLibzmq2_trace( "END mg_free (Message)" );
    return 1;
}

STATIC_INLINE MAGIC*
PerlLibzmq2_Message_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZMQ::LibZMQ2::Message: Invalid ZMQ::LibZMQ2::Message object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlLibzmq2_Context_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    PerlLibzmq2_Context* const ctxt = (PerlLibzmq2_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);

    PerlLibzmq2_trace("START mg_free (Context)");
    if (ctxt != NULL) {
#ifdef USE_ITHREADS
        PerlLibzmq2_trace( " + thread enabled. thread %p", aTHX );
        PerlLibzmq2_trace( " + context wrapper %p with zmq context %p", ctxt, ctxt->ctxt );
        if ( ctxt->interp == aTHX ) { /* is where I came from */
            PerlLibzmq2_trace( " + detected mg_free from creating thread %p, cleaning up", aTHX );
            zmq_term( ctxt->ctxt );
            mg->mg_ptr = NULL;
            Safefree(ctxt);
        }
#else
        PerlLibzmq2_trace(" + zmq context %p", ctxt);
        zmq_term( ctxt );
        mg->mg_ptr = NULL;
#endif
    }
    PerlLibzmq2_trace("END mg_free (Context)");
    return 1;
}

STATIC_INLINE MAGIC*
PerlLibzmq2_Context_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZMQ::LibZMQ2::Context: Invalid ZMQ::LibZMQ2::Context object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE int
PerlLibzmq2_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

STATIC_INLINE int
PerlLibzmq2_Socket_invalidate( PerlLibzmq2_Socket *sock )
{
    SV *ctxt_sv = sock->assoc_ctxt;
    int rv;

    PerlLibzmq2_trace("START socket_invalidate");
    PerlLibzmq2_trace(" + zmq socket %p", sock->socket);
    rv = zmq_close( sock->socket );

    if ( SvOK(ctxt_sv) ) {
        PerlLibzmq2_trace(" + associated context: %p", ctxt_sv);
        SvREFCNT_dec(ctxt_sv);
        sock->assoc_ctxt = NULL;
    }

    Safefree(sock);

    PerlLibzmq2_trace("END socket_invalidate");
    return rv;
}

STATIC_INLINE int
PerlLibzmq2_Socket_mg_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    PerlLibzmq2_Socket* const sock = (PerlLibzmq2_Socket *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    PerlLibzmq2_trace("START mg_free (Socket)");
    if (sock) {
        PerlLibzmq2_Socket_invalidate( sock );
        mg->mg_ptr = NULL;
    }
    PerlLibzmq2_trace("END mg_free (Socket)");
    return 1;
}

STATIC_INLINE int
PerlLibzmq2_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    mg->mg_ptr = NULL;
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    return 0;
}

STATIC_INLINE MAGIC*
PerlLibzmq2_Socket_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    croak("ZMQ::LibZMQ2::Socket: Invalid ZMQ::LibZMQ2::Socket object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE void 
PerlLibzmq2_free_string(void *data, void *hint) {
    PerlLibzmq2_trace("START free_string");
    PERL_UNUSED_ARG(hint);
    free(data);
    PerlLibzmq2_trace("END free_string");
}

#include "mg-xs.inc"

MODULE = ZMQ::LibZMQ2    PACKAGE = ZMQ::LibZMQ2::Constants 

INCLUDE: const-xs.inc

MODULE = ZMQ::LibZMQ2    PACKAGE = ZMQ::LibZMQ2   PREFIX = PerlLibzmq2_

PROTOTYPES: DISABLED

BOOT:
    {
        PerlLibzmq2_trace( "Booting Perl ZMQ::LibZMQ2" );
    }

void
PerlLibzmq2_zmq_version()
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

PerlLibzmq2_Context *
PerlLibzmq2_zmq_init( nthreads = 5 )
        int nthreads;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Context", 20 ));
    CODE:
        PerlLibzmq2_trace( "START zmq_init" );
#ifdef USE_ITHREADS
        PerlLibzmq2_trace( " + threads enabled, aTHX %p", aTHX );
        Newxz( RETVAL, 1, PerlLibzmq2_Context );
        RETVAL->interp = aTHX;
        RETVAL->ctxt   = zmq_init( nthreads );
        PerlLibzmq2_trace( " + created context wrapper %p", RETVAL );
        PerlLibzmq2_trace( " + zmq context %p", RETVAL->ctxt );
#else
        PerlLibzmq2_trace( " + non-threaded context");
        RETVAL = zmq_init( nthreads );
#endif
        PerlLibzmq2_trace( "END zmq_init");
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_term( context )
        PerlLibzmq2_Context *context;
    CODE:
#ifdef USE_ITHREADS
        RETVAL = zmq_term( context->ctxt );
#else
        RETVAL = zmq_term( context );
#endif
        if (RETVAL == 0) {
            /* Cancel the SV's mg attr so to not call zmq_term automatically */
            MAGIC *mg =
                PerlLibzmq2_Context_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq2_Context_vtbl );
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

PerlLibzmq2_Message *
PerlLibzmq2_zmq_msg_init()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Message", 20 ));
        int rc;
    CODE:
        Newxz( RETVAL, 1, PerlLibzmq2_Message );
        rc = zmq_msg_init( RETVAL );
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlLibzmq2_Message *
PerlLibzmq2_zmq_msg_init_size( size )
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Message", 20 ));
        int rc;
    CODE: 
        Newxz( RETVAL, 1, PerlLibzmq2_Message );
        rc = zmq_msg_init_size(RETVAL, size);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

PerlLibzmq2_Message *
PerlLibzmq2_zmq_msg_init_data( data, size = -1)
        SV *data;
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Message", 20 ));
        STRLEN x_data_len;
        char *sv_data = SvPV(data, x_data_len);
        char *x_data;
        int rc;
    CODE: 
        if (size >= 0) {
            x_data_len = size;
        }
        Newxz( RETVAL, 1, PerlLibzmq2_Message );
        x_data = (char *) malloc(x_data_len);
        memcpy(x_data, sv_data, x_data_len);
        rc = zmq_msg_init_data(RETVAL, x_data, x_data_len, PerlLibzmq2_free_string, NULL);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
        else {
            PerlLibzmq2_trace("zmq_msg_init_data created message %p", RETVAL);
        }
    OUTPUT:
        RETVAL

SV *
PerlLibzmq2_zmq_msg_data(message)
        PerlLibzmq2_Message *message;
    CODE:
        RETVAL = newSV(0);
        sv_setpvn( RETVAL, (char *) zmq_msg_data(message), (STRLEN) zmq_msg_size(message) );
    OUTPUT:
        RETVAL

size_t
PerlLibzmq2_zmq_msg_size(message)
        PerlLibzmq2_Message *message;
    CODE:
        RETVAL = zmq_msg_size(message);
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_msg_close(message)
        PerlLibzmq2_Message *message;
    CODE:
        PerlLibzmq2_trace("START zmq_msg_close");
        RETVAL = zmq_msg_close(message);
        Safefree(message);
        {
            MAGIC *mg =
                 PerlLibzmq2_Message_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq2_Message_vtbl );
             mg->mg_ptr = NULL;
        }
        /* mark the original SV's _closed flag as true */
        {
            SV *svr = SvRV(ST(0));
            if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                croak("PANIC: Failed to store closed flag on blessed reference");
            }
        }
        PerlLibzmq2_trace("END zmq_msg_close");
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_msg_move(dest, src)
        PerlLibzmq2_Message *dest;
        PerlLibzmq2_Message *src;
    CODE:
        RETVAL = zmq_msg_move( dest, src );
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_msg_copy (dest, src);
        PerlLibzmq2_Message *dest;
        PerlLibzmq2_Message *src;
    CODE:
        RETVAL = zmq_msg_copy( dest, src );
    OUTPUT:
        RETVAL

PerlLibzmq2_Socket *
PerlLibzmq2_zmq_socket (ctxt, type)
        PerlLibzmq2_Context *ctxt;
        IV type;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Socket", 19 ));
    CODE:
        PerlLibzmq2_trace( "START zmq_socket" );
        Newxz( RETVAL, 1, PerlLibzmq2_Socket );
        RETVAL->assoc_ctxt = NULL;
        RETVAL->socket = NULL;
#ifdef USE_ITHREADS
        PerlLibzmq2_trace( " + context wrapper %p, zmq context %p", ctxt, ctxt->ctxt );
        RETVAL->socket = zmq_socket( ctxt->ctxt, type );
#else
        PerlLibzmq2_trace( " + zmq context %p", ctxt );
        RETVAL->socket = zmq_socket( ctxt, type );
#endif
        RETVAL->assoc_ctxt = ST(0);
        SvREFCNT_inc(RETVAL->assoc_ctxt);
        PerlLibzmq2_trace( " + created socket %p", RETVAL );
        PerlLibzmq2_trace( "END zmq_socket" );
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_close(socket)
        PerlLibzmq2_Socket *socket;
    CODE:
        RETVAL = PerlLibzmq2_Socket_invalidate( socket );
        /* Cancel the SV's mg attr so to not call socket_invalidate again
           during Socket_mg_free
        */
        {
            MAGIC *mg =
                 PerlLibzmq2_Socket_mg_find( aTHX_ SvRV(ST(0)), &PerlLibzmq2_Socket_vtbl );
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
PerlLibzmq2_zmq_connect(socket, addr)
        PerlLibzmq2_Socket *socket;
        char *addr;
    CODE:
        PerlLibzmq2_trace( "START zmq_connect" );
        PerlLibzmq2_trace( " + socket %p", socket );
        RETVAL = zmq_connect( socket->socket, addr );
        if (RETVAL != 0) {
            croak( "%s", zmq_strerror( zmq_errno() ) );
        }
        PerlLibzmq2_trace( "END zmq_connect" );
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_bind(socket, addr)
        PerlLibzmq2_Socket *socket;
        char *addr;
    CODE:
        PerlLibzmq2_trace( "zmq_bind: socket %p", socket );
        RETVAL = zmq_bind( socket->socket, addr );
        if (RETVAL != 0) {
            croak( "%s", zmq_strerror( zmq_errno() ) );
        }
    OUTPUT:
        RETVAL

PerlLibzmq2_Message *
PerlLibzmq2_zmq_recv(socket, flags = 0)
        PerlLibzmq2_Socket *socket;
        int flags;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ2::Message", 20 ));
        int rv;
        zmq_msg_t msg;
    CODE:
        PerlLibzmq2_trace( "START zmq_recv" );
        RETVAL = NULL;
        zmq_msg_init(&msg);
        rv = zmq_recv(socket->socket, &msg, flags);
        PerlLibzmq2_trace(" + zmq recv with flags %d", flags);
        PerlLibzmq2_trace(" + zmq_recv returned with rv '%d'", rv);
        if (rv != 0) {
            SET_BANG;
            zmq_msg_close(&msg);
            PerlLibzmq2_trace(" + zmq_recv got bad status, closing temporary message");
        } else {
            Newxz(RETVAL, 1, PerlLibzmq2_Message);
            zmq_msg_init(RETVAL);
            zmq_msg_copy( RETVAL, &msg );
            zmq_msg_close(&msg);
            PerlLibzmq2_trace(" + zmq_recv created message %p", RETVAL );
        }
        PerlLibzmq2_trace( "END zmq_recv" );
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_send(socket, message, flags = 0)
        PerlLibzmq2_Socket *socket;
        SV *message;
        int flags;
    PREINIT:
        PerlLibzmq2_Message *msg = NULL;
    CODE:
        if (! SvOK(message))
            croak("ZMQ::LibZMQ2::Socket::send() NULL message passed");

        if (sv_isobject(message) && sv_isa(message, "ZMQ::LibZMQ2::Message")) {
            MAGIC *mg = PerlLibzmq2_Context_mg_find(aTHX_ SvRV(message), &PerlLibzmq2_Message_vtbl);
            if (mg) {
                msg = (PerlLibzmq2_Message *) mg->mg_ptr;
            }

            if (msg == NULL) {
                croak("Got invalid message object");
            }
            
            RETVAL = zmq_send(socket->socket, msg, flags);
        } else {
            STRLEN data_len;
            char *x_data;
            char *data = SvPV(message, data_len);
            zmq_msg_t msg;

            x_data = (char *)malloc(data_len);
            memcpy(x_data, data, data_len);
            zmq_msg_init_data(&msg, x_data, data_len, PerlLibzmq2_free_string, NULL);
            RETVAL = zmq_send(socket->socket, &msg, flags);
            zmq_msg_close( &msg ); 
        }
    OUTPUT:
        RETVAL

SV *
PerlLibzmq2_zmq_getsockopt_int(sock, option)
        PerlLibzmq2_Socket *sock;
        int option;

SV *
PerlLibzmq2_zmq_getsockopt_int64(sock, option)
        PerlLibzmq2_Socket *sock;
        int option;

SV *
PerlLibzmq2_zmq_getsockopt_uint64(sock, option)
        PerlLibzmq2_Socket *sock;
        int option;

SV *
PerlLibzmq2_zmq_getsockopt_string(sock, option, len = 1024)
        PerlLibzmq2_Socket *sock;
        int option;
        size_t len;

int
PerlLibzmq2_zmq_setsockopt_int(sock, option, val)
        PerlLibzmq2_Socket *sock;
        int option;
        int val;

int
PerlLibzmq2_zmq_setsockopt_int64(sock, option, val)
        PerlLibzmq2_Socket *sock;
        int option;
        int64_t val;

int
PerlLibzmq2_zmq_setsockopt_uint64(sock, option, val)
        PerlLibzmq2_Socket *sock;
        int option;
        uint64_t val;

int
PerlLibzmq2_zmq_setsockopt_string(sock, option, value)
        PerlLibzmq2_Socket *sock;
        int option;
        SV *value;
    PREINIT:
        size_t len;
        const char *string;
    CODE:
        string = SvPV( value, len );
        RETVAL = PerlLibzmq2_zmq_setsockopt_string(sock, option, string, len);
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_poll( list, timeout = 0 )
        AV *list;
        long timeout;
    PREINIT:
        I32 list_len;
        zmq_pollitem_t *pollitems;
        CV **callbacks;
        int i;
    CODE:
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
                if (! SvOK(*svr) || !sv_isobject( *svr) || ! sv_isa(*svr, "ZMQ::LibZMQ2::Socket")) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'socket' given for index %d", i);
                }
                mg = PerlLibzmq2_Socket_mg_find( aTHX_ SvRV(*svr), &PerlLibzmq2_Socket_vtbl );
                pollitems[i].socket = ((PerlLibzmq2_Socket *) mg->mg_ptr)->socket;
                PerlLibzmq2_trace( " + pollitem[%d].socket = %p", i, pollitems[i].socket );
            } else {
                svr = hv_fetch( elm, "fd", 2, NULL );
                if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'fd' given for index %d", i);
                }
                pollitems[i].fd = SvIV( *svr );
            }

            svr = hv_fetch( elm, "events", 6, NULL );
            if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'events' given for index %d", i);
            }
            pollitems[i].events = SvIV( *svr );

            svr = hv_fetch( elm, "callback", 8, NULL );
            if (svr == NULL || ! SvOK(*svr) || ! SvROK(*svr) || SvTYPE(SvRV(*svr)) != SVt_PVCV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'callback' given for index %d", i);
            }
            callbacks[i] = (CV *) SvRV( *svr );
        }

        /* now call zmq_poll */
        RETVAL = zmq_poll( pollitems, list_len, timeout );
        for ( i = 0; i < list_len; i++ ) {
            if (pollitems[i].revents & pollitems[i].events) {
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
        Safefree(pollitems);
        Safefree(callbacks);
    OUTPUT:
        RETVAL

int
PerlLibzmq2_zmq_device( device, insocket, outsocket )
        int device;
        PerlLibzmq2_Socket *insocket;
        PerlLibzmq2_Socket *outsocket;
    CODE:
        RETVAL = zmq_device( device, insocket->socket, outsocket->socket );
    OUTPUT:
        RETVAL


