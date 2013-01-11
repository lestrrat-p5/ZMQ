#ifndef  __PERL_ZEROMQ_H__
#define  __PERL_ZEROMQ_H__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <zmq.h>
#include <errno.h>
#include <unistd.h>

#ifndef PERLZMQ_TRACE
#define PERLZMQ_TRACE 0
#endif
#define _ERRNO        errno
#define SET_BANG      PerlLibzmq3_set_bang(aTHX_ _ERRNO)

typedef struct {
#ifdef tTHX /* tTHX doesn't exist in older perls */
    tTHX    interp;
#else
    PerlInterpreter *interp;
#endif
    pid_t   pid;
    void   *ctxt;
} PerlLibzmq3_Context;

typedef struct {
    void  *socket;
    SV    *assoc_ctxt; /* keep context around with sockets so we know */
    pid_t  pid;
} PerlLibzmq3_Socket;

typedef zmq_msg_t PerlLibzmq3_Message;

typedef struct {
    int bucket_size;
    int item_count;
    zmq_pollitem_t **items;
    char **item_ids;
    SV  **callbacks;
} PerlZMQ_PollItem;

/* ZMQ_PULL was introduced for version 3, but it exists in git head.
 * it's just rename of ZMQ_UPSTREAM and ZMQ_DOWNSTREAM so we just
 * fake it here
 */
#ifndef ZMQ_PULL
#define ZMQ_PULL ZMQ_UPSTREAM
#endif

#ifndef ZMQ_PUSH
#define ZMQ_PUSH ZMQ_DOWNSTREAM
#endif

#define P5ZMQ3_STRUCT2SV (arg, var, klass, type) \
    { \
        if (!var)          /* if null */ \
            SvOK_off(arg); /* then return as undef instead of reaf to undef */ \
        else { \
            /* setup $arg as a ref to a blessed hash hv */ \
            MAGIC *mg; \
            HV *hv = newHV(); \
            const char *classname = #klass; \
            /* take (sub)class name to use from class_sv if appropriate */ \
            if (SvMAGICAL(class_sv)) \
                mg_get(class_sv); \
    \            if (SvOK( class_sv ) && sv_derived_from(class_sv, classname ) ) { \
                if(SvROK(class_sv) && SvOBJECT(SvRV(class_sv))) { \
                    classname = sv_reftype(SvRV(class_sv), TRUE); \
                } else { \
                    classname = SvPV_nolen(class_sv); \
                } \
            } \
    \
            sv_setsv(arg, sv_2mortal(newRV_noinc((SV*)hv))); \
            (void)sv_bless(arg, gv_stashpv(classname, TRUE)); \
            mg = sv_magicext((SV*)hv, NULL, PERL_MAGIC_ext, &type##_vtbl, (char*) var, 0); \
            mg->mg_flags |= MGf_DUP; \
        } \
    }

#define P5ZMQ3_SV2STRUCT(arg, var, klass, type, errcode) \
    { \
        MAGIC *mg; \
        var = NULL; \
        if (! sv_isobject(arg)) { \
            croak("Argument is not an object"); \
        } \
    \
        /* if it got here, it's a blessed reference. better be an HV */ \
        { \
            SV *svr; \
            SV **closed; \
            svr = SvRV(arg); \
            if (! svr ) { \
                croak("PANIC: Could not get reference from blessed object."); \
            } \
    \
            if (SvTYPE(svr) != SVt_PVHV) { \
                croak("PANIC: Underlying storage of blessed reference is not a hash."); \
            } \
    \
            closed = hv_fetchs( (HV *) svr, "_closed", 0 ); \
            if (closed != NULL && SvTRUE(*closed)) { \
                /* if it's already closed, just return */ \
                err = errcode; \
                PerlLibzmq3_set_bang( aTHX_ err); \
                XSRETURN_EMPTY; \
            } \
        } \
    \
        mg = type##_mg_find(aTHX_ SvRV(arg), &type##_vtbl); \
        if (mg) { \
            var = (type *) mg->mg_ptr; \
        } \
    \
        if (var == NULL) \
            croak("Invalid ##klass## object (perhaps you've already freed it?)"); \
    }

#endif /* __PERL_ZERMQ_H__ */