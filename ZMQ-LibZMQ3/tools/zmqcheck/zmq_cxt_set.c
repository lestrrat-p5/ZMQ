#include "EXTERN.h"
#include "perl.h"
#include <zmq.h>

int main(int argc, char **argv)
{
    PERL_UNUSED_VAR(argc);
    PERL_UNUSED_VAR(argv);
    zmq_cxt_set(NULL, 0, 0);
}