#include "perl_libzmq3.h"

STATIC_INLINE
void
P5ZMQ3_set_bang(pTHX_ int err) {
    SV *errsv = get_sv("!", GV_ADD);
    P5ZMQ3_TRACE(" + Set ERRSV ($!) to %d", err);
    sv_setiv(errsv, err);
    sv_setpv(errsv, zmq_strerror(err));
    errno = err;
}

STATIC_INLINE
SV *
P5ZMQ3_zmq_getsockopt_int(P5ZMQ3_Socket *sock, int option) {
    size_t len;
    int    status;
    I32    i32;
    SV     *sv = newSV(0);

    len = sizeof(i32);
    status = zmq_getsockopt(sock->socket, option, &i32, &len);
    if(status == 0) {
        sv_setiv(sv, i32);
    } else {
        SET_BANG;
    }
    return sv;
}

STATIC_INLINE
SV *
P5ZMQ3_zmq_getsockopt_int64(P5ZMQ3_Socket *sock, int option) {
    size_t  len;
    int     status;
    int64_t i64;
    SV      *sv = newSV(0);

    len = sizeof(i64);
    status = zmq_getsockopt(sock->socket, option, &i64, &len);
    if(status == 0) {
        sv_setiv(sv, i64);
    } else {
        SET_BANG;
    }
    return sv;
}

STATIC_INLINE
SV *
P5ZMQ3_zmq_getsockopt_uint64(P5ZMQ3_Socket *sock, int option) {
    size_t len;
    int    status;
    uint64_t u64;
    SV *sv = newSV(0);

    len = sizeof(u64);
    status = zmq_getsockopt(sock->socket, option, &u64, &len);
    if(status == 0) {
        sv_setuv(sv, u64);
    } else {
        SET_BANG;
    }
    return sv;
}

STATIC_INLINE
SV *
P5ZMQ3_zmq_getsockopt_string(P5ZMQ3_Socket *sock, int option, size_t len) {
    int    status;
    char   *string;
    SV     *sv = newSV(0);

    Newxz(string, len, char);
    status = zmq_getsockopt(sock->socket, option, string, &len);
    if(status == 0) {
        sv_setpvn(sv, string, len);
    } else {
        SET_BANG;
    }
    Safefree(string);

    return sv;
}


STATIC_INLINE
int
P5ZMQ3_zmq_setsockopt_int( P5ZMQ3_Socket *sock, int option, int val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE
int
P5ZMQ3_zmq_setsockopt_int64( P5ZMQ3_Socket *sock, int option, int64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(int64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE
int
P5ZMQ3_zmq_setsockopt_uint64(P5ZMQ3_Socket *sock, int option, uint64_t val) {
    int status;
    status = zmq_setsockopt(sock->socket, option, &val, sizeof(uint64_t));
    if (status != 0) {
        SET_BANG;
    }
    return status;
}
    
STATIC_INLINE
int
P5ZMQ3_zmq_setsockopt_string(P5ZMQ3_Socket *sock, int option, const char *ptr, size_t len) {
    int status;
    status = zmq_setsockopt(sock->socket, option, ptr, len);
    if (status != 0) {
        SET_BANG;
    }
    return status;
}

STATIC_INLINE
int
P5ZMQ3_Message_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
    P5ZMQ3_Message *const src = (P5ZMQ3_Message *) mg->mg_ptr;
    P5ZMQ3_Message *dest;

    P5ZMQ3_TRACE("Message -> dup");
    PERL_UNUSED_VAR( param );
 
    Newxz( dest, 1, P5ZMQ3_Message );
    zmq_msg_init( dest );
    zmq_msg_copy ( dest, src );
    mg->mg_ptr = (char *) dest;
    return 0;
}

STATIC_INLINE
int
P5ZMQ3_Message_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    P5ZMQ3_Message* const msg = (P5ZMQ3_Message *) mg->mg_ptr;

    PERL_UNUSED_VAR(sv);
    P5ZMQ3_TRACE( "START mg_free (Message)" );
    if ( msg != NULL ) {
        P5ZMQ3_TRACE( " + zmq message %p", msg );
        zmq_msg_close( msg );
        Safefree( msg );
    }
    P5ZMQ3_TRACE( "END mg_free (Message)" );
    return 1;
}

STATIC_INLINE
MAGIC*
P5ZMQ3_Message_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
    MAGIC* mg;

    assert(sv   != NULL);
    assert(vtbl != NULL);

    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
        if(mg->mg_virtual == vtbl){
            assert(mg->mg_type == PERL_MAGIC_ext);
            return mg;
        }
    }

    P5ZMQ3_TRACE( "mg_find (Message)" );
    P5ZMQ3_TRACE( " + SV %p", sv )
    croak("ZMQ::LibZMQ3::Message: Invalid ZMQ::LibZMQ3::Message object was passed to mg_find");
    return NULL; /* not reached */
}

STATIC_INLINE
int
P5ZMQ3_Context_invalidate( P5ZMQ3_Context *ctxt ) {
    int rv = -1;
    int close = 1;
    if (ctxt->ctxt == NULL) {
        close = 0;
        P5ZMQ3_TRACE( " + context already seems to be freed");
    }

    if (ctxt->pid != getpid()) {
        close = 0;
        P5ZMQ3_TRACE( " + context was not created in this process");
    }

#ifdef USE_ITHREADS
    if (ctxt->interp != aTHX) {
        close = 0;
        P5ZMQ3_TRACE( " + context was not created in this thread");
    }
#endif
    if (close) {
#ifdef HAS_ZMQ_CTX_DESTROY
        P5ZMQ3_TRACE( " + calling actual zmq_ctx_destroy()");
        rv = zmq_ctx_destroy( ctxt->ctxt );
#else
        P5ZMQ3_TRACE( " + calling actual zmq_term()");
        rv = zmq_term( ctxt->ctxt );
#endif
        if ( rv != 0 ) {
            SET_BANG;
        } else {
#ifdef USE_ITHREADS
            ctxt->interp = NULL;
#endif
            ctxt->ctxt   = NULL;
            ctxt->pid    = 0;
            Safefree(ctxt);
        }
    }
    return rv;
}

STATIC_INLINE
int
P5ZMQ3_Context_mg_free( pTHX_ SV * const sv, MAGIC *const mg ) {
    P5ZMQ3_Context* const ctxt = (P5ZMQ3_Context *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);

    P5ZMQ3_TRACE("START mg_free (Context)");
    if (ctxt != NULL) {
        P5ZMQ3_Context_invalidate( ctxt );
        mg->mg_ptr = NULL;
    }
    P5ZMQ3_TRACE("END mg_free (Context)");
    return 1;
}

STATIC_INLINE
MAGIC*
P5ZMQ3_Context_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
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

STATIC_INLINE
int
P5ZMQ3_Context_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
    return 0;
}

STATIC_INLINE
int
P5ZMQ3_Socket_invalidate( P5ZMQ3_Socket *sock )
{
    SV *ctxt_sv = sock->assoc_ctxt;
    int rv;

    P5ZMQ3_TRACE("START socket_invalidate");
    if (sock->pid != getpid()) {
        return 0;
    }

    P5ZMQ3_TRACE(" + zmq socket %p", sock->socket);
    rv = zmq_close( sock->socket );

    if ( SvOK(ctxt_sv) ) {
        P5ZMQ3_TRACE(" + associated context: %p", ctxt_sv);
        SvREFCNT_dec(ctxt_sv);
        sock->assoc_ctxt = NULL;
    }

    Safefree(sock);

    P5ZMQ3_TRACE("END socket_invalidate");
    return rv;
}

STATIC_INLINE
int
P5ZMQ3_Socket_mg_free(pTHX_ SV* const sv, MAGIC* const mg)
{
    P5ZMQ3_Socket* const sock = (P5ZMQ3_Socket *) mg->mg_ptr;
    PERL_UNUSED_VAR(sv);
    P5ZMQ3_TRACE("START mg_free (Socket)");
    if (sock) {
        P5ZMQ3_Socket_invalidate( sock );
        mg->mg_ptr = NULL;
    }
    P5ZMQ3_TRACE("END mg_free (Socket)");
    return 1;
}

STATIC_INLINE
int
P5ZMQ3_Socket_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param){
    P5ZMQ3_TRACE("START mg_dup (Socket)");
#ifdef USE_ITHREADS /* single threaded perl has no "xxx_dup()" APIs */
    mg->mg_ptr = NULL;
    PERL_UNUSED_VAR(param);
#else
    PERL_UNUSED_VAR(mg);
    PERL_UNUSED_VAR(param);
#endif
    P5ZMQ3_TRACE("END mg_dup (Socket)");
    return 0;
}

STATIC_INLINE
MAGIC*
P5ZMQ3_Socket_mg_find(pTHX_ SV* const sv, const MGVTBL* const vtbl){
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

STATIC_INLINE
void 
PerlZMQ_free_string(void *data, void *hint) {
    PERL_SET_CONTEXT(hint);
    Safefree( (char *) data );
}

#include "mg-xs.inc"

MODULE = ZMQ::LibZMQ3    PACKAGE = ZMQ::LibZMQ3   PREFIX = P5ZMQ3_

PROTOTYPES: DISABLED

BOOT:
    {
        P5ZMQ3_TRACE( "Booting ZMQ::LibZMQ3" );
#include "constants-xs.inc"
    }


int
zmq_errno()

const char *
zmq_strerror(num)
        int num;

void
P5ZMQ3_zmq_version()
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

P5ZMQ3_Context *
P5ZMQ3_zmq_init( nthreads = 5 )
        int nthreads;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Context", 20 ));
        void *cxt;
    CODE:
#ifdef HAS_ZMQ_INIT
        P5ZMQ3_TRACE( "START zmq_init" );
        cxt = zmq_init( nthreads );
        if (cxt == NULL) {
            SET_BANG;
            RETVAL = NULL;
        } else {
            Newxz( RETVAL, 1, P5ZMQ3_Context );
            P5ZMQ3_TRACE( " + created context wrapper %p", RETVAL );
            RETVAL->pid    = getpid();
            RETVAL->ctxt   = cxt;
#ifdef USE_ITHREADS
            P5ZMQ3_TRACE( " + threads enabled, aTHX %p", aTHX );
            RETVAL->interp = aTHX;
#endif
            P5ZMQ3_TRACE( " + zmq context %p", RETVAL->ctxt );
        }
        P5ZMQ3_TRACE( "END zmq_init");
#else /* HAS_ZMQ_INIT */
        PERL_UNUSED_VAR(cxt);
        PERL_UNUSED_VAR(nthreads);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_init");
#endif
    OUTPUT:
        RETVAL

P5ZMQ3_Context *
P5ZMQ3_zmq_ctx_new( nthreads = 5 )
        int nthreads;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Context", 20 ));
        void *cxt;
    CODE:
#ifdef HAS_ZMQ_CTX_NEW
        P5ZMQ3_TRACE( "START zmq_ctx_new" );
        cxt = zmq_init( nthreads );
        if (cxt == NULL) {
            SET_BANG;
            RETVAL = NULL;
        } else {
            Newxz( RETVAL, 1, P5ZMQ3_Context );
            P5ZMQ3_TRACE( " + created context wrapper %p", RETVAL );
            RETVAL->pid    = getpid();
            RETVAL->ctxt   = cxt;
#ifdef USE_ITHREADS
            P5ZMQ3_TRACE( " + threads enabled, aTHX %p", aTHX );
            RETVAL->interp = aTHX;
#endif
            P5ZMQ3_TRACE( " + zmq context %p", RETVAL->ctxt );
        }
        P5ZMQ3_TRACE( "END zmq_ctx_new");
#else /* HAS_ZMQ_CTX_NEW */
        PERL_UNUSED_VAR(cxt);
        PERL_UNUSED_VAR(nthreads);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_ctx_new");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_term( ctxt )
        P5ZMQ3_Context *ctxt;
    CODE:
#ifdef HAS_ZMQ_TERM
        RETVAL = P5ZMQ3_Context_invalidate( ctxt );

        if (RETVAL == 0) {
            /* Cancel the SV's mg attr so to not call zmq_term automatically */
            MAGIC *mg =
                P5ZMQ3_Context_mg_find( aTHX_ SvRV(ST(0)), &P5ZMQ3_Context_vtbl );
            mg->mg_ptr = NULL;
            /* mark the original SV's _closed flag as true */
            {
                SV *svr = SvRV(ST(0));
                if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                    croak("PANIC: Failed to store closed flag on blessed reference");
                }
            }
        }
#else /* HAS_ZMQ_TERM */
        PERL_UNUSED_VAR(ctxt);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_term");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_ctx_destroy( ctxt )
        P5ZMQ3_Context *ctxt;
    CODE:
#ifdef HAS_ZMQ_CTX_DESTROY
        RETVAL = P5ZMQ3_Context_invalidate( ctxt );

        if (RETVAL == 0) {
            /* Cancel the SV's mg attr so to not call zmq_ctx_destroy automatically */
            MAGIC *mg =
                P5ZMQ3_Context_mg_find( aTHX_ SvRV(ST(0)), &P5ZMQ3_Context_vtbl );
            mg->mg_ptr = NULL;
            /* mark the original SV's _closed flag as true */
            {
                SV *svr = SvRV(ST(0));
                if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                    croak("PANIC: Failed to store closed flag on blessed reference");
                }
            }
        }
#else /* HAS_ZMQ_CTX_DESTROY */
        PERL_UNUSED_VAR(ctxt);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_ctx_destroy");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_ctx_get(ctxt, option_name)
        P5ZMQ3_Context *ctxt;
        int option_name;
    CODE:
#ifdef HAS_ZMQ_CTX_GET
        RETVAL = zmq_ctx_get(ctxt->ctxt, option_name);
        if (RETVAL == -1) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(ctxt);
        PERL_UNUSED_VAR(option_name);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_ctx_get");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_ctx_set(ctxt, option_name, option_value)
        P5ZMQ3_Context *ctxt;
        int option_name;
        int option_value;
    CODE:
#ifdef HAS_ZMQ_CTX_SET
        RETVAL = zmq_ctx_set(ctxt->ctxt, option_name, option_value);
        if (RETVAL == -1) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(ctxt);
        PERL_UNUSED_VAR(option_name);
        PERL_UNUSED_VAR(option_value);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_ctx_set");
#endif
    OUTPUT:
        RETVAL

P5ZMQ3_Message *
P5ZMQ3_zmq_msg_init()
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rc;
    CODE:
        Newxz( RETVAL, 1, P5ZMQ3_Message );
        rc = zmq_msg_init( RETVAL );
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

P5ZMQ3_Message *
P5ZMQ3_zmq_msg_init_size( size )
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rc;
    CODE: 
        Newxz( RETVAL, 1, P5ZMQ3_Message );
        rc = zmq_msg_init_size(RETVAL, size);
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

P5ZMQ3_Message *
P5ZMQ3_zmq_msg_init_data( data, size = -1)
        SV *data;
        IV size;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        STRLEN x_data_len;
        char *sv_data = SvPV(data, x_data_len);
        char *x_data;
        int rc;
    CODE: 
        P5ZMQ3_TRACE("START zmq_msg_init_data");
        if (size >= 0) {
            x_data_len = size;
        }
        Newxz( RETVAL, 1, P5ZMQ3_Message );
        Newxz( x_data, x_data_len, char );
        Copy( sv_data, x_data, x_data_len, char );
        rc = zmq_msg_init_data(RETVAL, x_data, x_data_len, PerlZMQ_free_string, Perl_get_context());
        if ( rc != 0 ) {
            SET_BANG;
            zmq_msg_close( RETVAL );
            RETVAL = NULL;
        }
        else {
            P5ZMQ3_TRACE(" + zmq_msg_init_data created message %p", RETVAL);
        }
        P5ZMQ3_TRACE("END zmq_msg_init_data");
    OUTPUT:
        RETVAL

SV *
P5ZMQ3_zmq_msg_data(message)
        P5ZMQ3_Message *message;
    CODE:
        P5ZMQ3_TRACE( "START zmq_msg_data" );
        P5ZMQ3_TRACE( " + message content '%s'", (char *) zmq_msg_data(message) );
        P5ZMQ3_TRACE( " + message size '%d'", (int) zmq_msg_size(message) );
        RETVAL = newSV(0);
        sv_setpvn( RETVAL, (char *) zmq_msg_data(message), (STRLEN) zmq_msg_size(message) );
        P5ZMQ3_TRACE( "END zmq_msg_data" );
    OUTPUT:
        RETVAL

size_t
P5ZMQ3_zmq_msg_size(message)
        P5ZMQ3_Message *message;
    CODE:
        RETVAL = zmq_msg_size(message);
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_msg_close(message)
        P5ZMQ3_Message *message;
    CODE:
        P5ZMQ3_TRACE("START zmq_msg_close");
        RETVAL = zmq_msg_close(message);
        Safefree(message);
        if (RETVAL != 0) {
            SET_BANG;
        }

        {
            MAGIC *mg =
                 P5ZMQ3_Message_mg_find( aTHX_ SvRV(ST(0)), &P5ZMQ3_Message_vtbl );
             mg->mg_ptr = NULL;
        }
        /* mark the original SV's _closed flag as true */
        {
            SV *svr = SvRV(ST(0));
            if (hv_stores( (HV *) svr, "_closed", &PL_sv_yes ) == NULL) {
                croak("PANIC: Failed to store closed flag on blessed reference");
            }
        }
        P5ZMQ3_TRACE("END zmq_msg_close");
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_msg_move(dest, src)
        P5ZMQ3_Message *dest;
        P5ZMQ3_Message *src;
    CODE:
        RETVAL = zmq_msg_move( dest, src );
        if (RETVAL != 0) {
            SET_BANG;
        }
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_msg_copy (dest, src);
        P5ZMQ3_Message *dest;
        P5ZMQ3_Message *src;
    CODE:
        RETVAL = zmq_msg_copy( dest, src );
        if (RETVAL != 0) {
            SET_BANG;
        }
    OUTPUT:
        RETVAL

P5ZMQ3_Socket *
P5ZMQ3_zmq_socket (ctxt, type)
        P5ZMQ3_Context *ctxt;
        IV type;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Socket", 19 ));
        void *sock = NULL;
    CODE:
        P5ZMQ3_TRACE( "START zmq_socket" );
        sock = zmq_socket( ctxt->ctxt, type );
        if (sock == NULL) {
            RETVAL = NULL;
            SET_BANG;
        } else {
            Newxz( RETVAL, 1, P5ZMQ3_Socket );
            RETVAL->assoc_ctxt = ST(0);
            RETVAL->socket = sock;
            RETVAL->pid = getpid();
            (void) SvREFCNT_inc(RETVAL->assoc_ctxt);
            P5ZMQ3_TRACE( " + created socket %p", RETVAL );
        }
        P5ZMQ3_TRACE( "END zmq_socket" );
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_close(socket)
        P5ZMQ3_Socket *socket;
    CODE:
        RETVAL = P5ZMQ3_Socket_invalidate( socket );
        /* Cancel the SV's mg attr so to not call socket_invalidate again
           during Socket_mg_free
        */
        {
            MAGIC *mg =
                 P5ZMQ3_Socket_mg_find( aTHX_ SvRV(ST(0)), &P5ZMQ3_Socket_vtbl );
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
P5ZMQ3_zmq_connect(socket, addr)
        P5ZMQ3_Socket *socket;
        char *addr;
    CODE:
        P5ZMQ3_TRACE( "START zmq_connect" );
        P5ZMQ3_TRACE( " + socket %p", socket );
        RETVAL = zmq_connect( socket->socket, addr );
        P5ZMQ3_TRACE(" + zmq_connect returned with rv '%d'", RETVAL);
        if (RETVAL != 0) {
            SET_BANG;
        }
        P5ZMQ3_TRACE( "END zmq_connect" );
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_disconnect(socket, addr)
        P5ZMQ3_Socket *socket;
        const char *addr;
    CODE:
#ifdef HAS_ZMQ_DISCONNECT
        RETVAL = zmq_disconnect(socket, addr);
        if (RETVAL != 0) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(addr);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_disconnect");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_bind(socket, addr)
        P5ZMQ3_Socket *socket;
        char *addr;
    CODE:
        P5ZMQ3_TRACE( "START zmq_bind" );
        P5ZMQ3_TRACE( " + socket %p", socket );
        RETVAL = zmq_bind( socket->socket, addr );
        P5ZMQ3_TRACE(" + zmq_bind returned with rv '%d'", RETVAL);
        if (RETVAL != 0) {
            SET_BANG;
        }
        P5ZMQ3_TRACE( "END zmq_bind" );
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_unbind(socket, addr)
        P5ZMQ3_Socket *socket;
        const char *addr;
    CODE:
#ifdef HAS_ZMQ_UNBIND
        RETVAL = zmq_unbind(socket, addr);
        if (RETVAL == -1) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(addr);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_unbind");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_recv(socket, buf_sv, len, flags = 0)
        P5ZMQ3_Socket *socket;
        SV *buf_sv;
        size_t len;
        int flags;
    PREINIT:
        char *buf;
    CODE:
        P5ZMQ3_TRACE( "START zmq_recv" );
        Newxz( buf, len, char );

        RETVAL = zmq_recv( socket->socket, buf, len, flags );
        P5ZMQ3_TRACE(" + zmq_recv returned with rv '%d'", RETVAL);
        if ( RETVAL == -1 ) {
            SET_BANG;
        } else {
            sv_setpvn( buf_sv, buf, len );
        }
        Safefree(buf);
        P5ZMQ3_TRACE( "END zmq_recv" );
    OUTPUT:
        RETVAL
        
int
P5ZMQ3_zmq_msg_recv(msg, socket, flags = 0)
        P5ZMQ3_Message *msg;
        P5ZMQ3_Socket *socket;
        int flags;
    CODE:
#ifndef HAS_ZMQ_MSG_RECV
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_msg_recv");
#else
        P5ZMQ3_TRACE( "START zmq_msg_recv" );
        RETVAL = zmq_msg_recv(msg, socket->socket, flags);
        P5ZMQ3_TRACE(" + zmq_msg_recv returned with rv '%d'", RETVAL);
        if (RETVAL == -1) {
            SET_BANG;
            P5ZMQ3_TRACE(" + zmq_msg_recv got bad status");
        }
        P5ZMQ3_TRACE( "END zmq_msg_recv" );
#endif /* HAS_ZMQ_RCVMSG */
    OUTPUT:
        RETVAL

P5ZMQ3_Message *
P5ZMQ3_zmq_recvmsg(socket, flags = 0)
        P5ZMQ3_Socket *socket;
        int flags;
    PREINIT:
        SV *class_sv = sv_2mortal(newSVpvn( "ZMQ::LibZMQ3::Message", 20 ));
        int rv;
    CODE:
#ifndef HAS_ZMQ_RECVMSG
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_recvmsg");
#else
        P5ZMQ3_TRACE( "START zmq_recvmsg" );
        Newxz(RETVAL, 1, P5ZMQ3_Message);
        rv = zmq_msg_init(RETVAL);
        if (rv != 0) {
            SET_BANG;
            P5ZMQ3_TRACE("zmq_msg_init failed (%d)", rv);
            XSRETURN_EMPTY;
        }
        rv = zmq_recvmsg(socket->socket, RETVAL, flags);
        P5ZMQ3_TRACE(" + zmq_recvmsg with flags %d", flags);
        P5ZMQ3_TRACE(" + zmq_recvmsg returned with rv '%d'", rv);
        if (rv == -1) {
            SET_BANG;
            P5ZMQ3_TRACE(" + zmq_recvmsg got bad status, closing temporary message");
            zmq_msg_close(RETVAL);
            Safefree(RETVAL);
            XSRETURN_EMPTY;
        }
        P5ZMQ3_TRACE( "END zmq_recvmsg" );
#endif /* HAS_ZMQ_RCVMSG */
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_send(socket, message, size = -1, flags = 0)
        P5ZMQ3_Socket *socket;
        SV *message;
        int size;
        int flags;
    PREINIT:
        char *message_buf;
        STRLEN usize;
    CODE:
        P5ZMQ3_TRACE( "START zmq_send" );
        if (! SvOK(message))
            croak("ZMQ::LibZMQ3::zmq_send(): NULL message passed");

        message_buf = SvPV( message, usize );
        if ( size != -1 && (STRLEN)size < usize )
            usize = (STRLEN)size;

        P5ZMQ3_TRACE( " + buffer '%s' (%zu)", message_buf, usize );
        P5ZMQ3_TRACE( " + flags %d", flags);
        RETVAL = zmq_send( socket->socket, message_buf, usize, flags );
        P5ZMQ3_TRACE( " + zmq_send returned with rv '%d'", RETVAL );
        if ( RETVAL == -1 ) {
            P5ZMQ3_TRACE( " ! zmq_send error %s", zmq_strerror( zmq_errno() ) );
            SET_BANG;
        }
        P5ZMQ3_TRACE( "END zmq_send" );
    OUTPUT:
        RETVAL

int
P5ZMQ3__zmq_msg_send(message, socket, flags = 0)
        P5ZMQ3_Message *message;
        P5ZMQ3_Socket *socket;
        int flags;
    CODE:
#ifndef HAS_ZMQ_MSG_SEND
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_msg_send");
#else
        P5ZMQ3_TRACE( "START zmq_msg_send" );
        RETVAL = zmq_msg_send(message, socket->socket, flags);
        P5ZMQ3_TRACE( " + zmq_msg_send returned with rv '%d'", RETVAL );
        if ( RETVAL == -1 ) {
            P5ZMQ3_TRACE( " ! zmq_msg_send error %s", zmq_strerror( zmq_errno() ) );
            SET_BANG;
        }
        P5ZMQ3_TRACE( "END zmq_msg_send" );
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3__zmq_sendmsg(socket, message, flags = 0)
        P5ZMQ3_Socket *socket;
        P5ZMQ3_Message *message;
        int flags;
    CODE:
#ifndef HAS_ZMQ_SENDMSG
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_sendmsg");
#else
        P5ZMQ3_TRACE( "START zmq_sendmsg" );
        RETVAL = zmq_sendmsg(socket->socket, message, flags);
        P5ZMQ3_TRACE( " + zmq_sendmsg returned with rv '%d'", RETVAL );
        if ( RETVAL == -1 ) {
            P5ZMQ3_TRACE( " ! zmq_sendmsg error %s", zmq_strerror( zmq_errno() ) );
            SET_BANG;
        }
        P5ZMQ3_TRACE( "END zmq_sendmsg" );
#endif
    OUTPUT:
        RETVAL

SV *
P5ZMQ3_zmq_getsockopt_int(sock, option)
        P5ZMQ3_Socket *sock;
        int option;

SV *
P5ZMQ3_zmq_getsockopt_int64(sock, option)
        P5ZMQ3_Socket *sock;
        int option;

SV *
P5ZMQ3_zmq_getsockopt_uint64(sock, option)
        P5ZMQ3_Socket *sock;
        int option;

SV *
P5ZMQ3_zmq_getsockopt_string(sock, option, len = 1024)
        P5ZMQ3_Socket *sock;
        int option;
        size_t len;

int
P5ZMQ3_zmq_setsockopt_int(sock, option, val)
        P5ZMQ3_Socket *sock;
        int option;
        int val;

int
P5ZMQ3_zmq_setsockopt_int64(sock, option, val)
        P5ZMQ3_Socket *sock;
        int option;
        int64_t val;

int
P5ZMQ3_zmq_setsockopt_uint64(sock, option, val)
        P5ZMQ3_Socket *sock;
        int option;
        uint64_t val;

int
P5ZMQ3_zmq_setsockopt_string(sock, option, value)
        P5ZMQ3_Socket *sock;
        int option;
        SV *value;
    PREINIT:
        size_t len;
        const char *string;
    CODE:
        string = SvPV( value, len );
        RETVAL = P5ZMQ3_zmq_setsockopt_string(sock, option, string, len);
    OUTPUT:
        RETVAL

void
P5ZMQ3_zmq_poll( list, timeout = 0 )
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
        P5ZMQ3_TRACE( "START zmq_poll" );

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

            P5ZMQ3_TRACE( " + processing element %d", i );
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
                mg = P5ZMQ3_Socket_mg_find( aTHX_ SvRV(*svr), &P5ZMQ3_Socket_vtbl );
                pollitems[i].socket = ((P5ZMQ3_Socket *) mg->mg_ptr)->socket;
                P5ZMQ3_TRACE( " + via pollitem[%d].socket = %p", i, pollitems[i].socket );
            } else {
                svr = hv_fetch( elm, "fd", 2, NULL );
                if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                    Safefree( pollitems );
                    Safefree( callbacks );
                    croak("Invalid 'fd' given for index %d", i);
                }
                pollitems[i].fd = SvIV( *svr );
                P5ZMQ3_TRACE( " + via pollitem[%d].fd = %d", i, pollitems[i].fd );
            }

            svr = hv_fetch( elm, "events", 6, NULL );
            if (svr == NULL || ! SvOK(*svr) || SvTYPE(*svr) != SVt_IV) {
                Safefree( pollitems );
                Safefree( callbacks );
                croak("Invalid 'events' given for index %d", i);
            }
            pollitems[i].events = SvIV( *svr );
            P5ZMQ3_TRACE( " + going to poll events %d", pollitems[i].events );

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
        P5ZMQ3_TRACE( " + zmq_poll returned with rv '%d'", RETVAL );

        if (rv != -1 ) {
            for ( i = 0; i < list_len; i++ ) {
                P5ZMQ3_TRACE( " + checking events for %d", i );
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
        P5ZMQ3_TRACE( "END zmq_poll" );

int
P5ZMQ3_zmq_device( device, insocket, outsocket )
        int device;
        P5ZMQ3_Socket *insocket;
        P5ZMQ3_Socket *outsocket;
    CODE:
#ifdef HAS_ZMQ_DEVICE
        RETVAL = zmq_device( device, insocket->socket, outsocket->socket );
        if (RETVAL != 0) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(device);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_device");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_proxy(frontend, backend, capture = NULL)
        P5ZMQ3_Socket *frontend;
        P5ZMQ3_Socket *backend;
        P5ZMQ3_Socket *capture;
    CODE:
#ifdef HAS_ZMQ_PROXY
        if (capture) {
          capture = capture->socket;
        }
        RETVAL = zmq_proxy(frontend->socket, backend->socket, capture);
        if (RETVAL != 0) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(frontend);
        PERL_UNUSED_VAR(backend);
        PERL_UNUSED_VAR(capture);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_proxy");
#endif
    OUTPUT:
        RETVAL

int
P5ZMQ3_zmq_socket_monitor(socket, addr, events)
        P5ZMQ3_Socket *socket;
        char *addr;
        int events;
    CODE:
#ifdef HAS_ZMQ_SOCKET_MONITOR
        RETVAL = zmq_socket_monitor(socket, addr, events);
        if (RETVAL != 0) {
            SET_BANG;
        }
#else
        PERL_UNUSED_VAR(socket);
        PERL_UNUSED_VAR(addr);
        PERL_UNUSED_VAR(events);
        P5ZMQ3_FUNCTION_UNAVAILABLE("zmq_socket_monitor");
#endif
    OUTPUT:
        RETVAL

