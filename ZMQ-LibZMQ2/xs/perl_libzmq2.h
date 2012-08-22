#ifndef  __PERL_LIBZMQ2_H__
#define  __PERL_LIBZMQ2_H__
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
#define SET_BANG      PerlLibzmq2_set_bang(aTHX_ _ERRNO)

typedef struct {
#ifdef tTHX /* tTHX doesn't exist in older perls */
    tTHX    interp;
#else
    PerlInterpreter *interp;
#endif
    void   *ctxt;
    pid_t   pid;
} PerlLibzmq2_Context;

typedef struct {
    void  *socket;
    SV    *assoc_ctxt; /* keep context around with sockets so we know */
    pid_t  pid;
} PerlLibzmq2_Socket;

typedef zmq_msg_t PerlLibzmq2_Message;

typedef struct {
    int bucket_size;
    int item_count;
    zmq_pollitem_t **items;
    char **item_ids;
    SV  **callbacks;
} PerlLibzmq2_PollItem;

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

#endif /* __PERL_ZERMQ_H__ */