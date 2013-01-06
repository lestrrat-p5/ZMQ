/* why is this here?
   if pkg-config is available, fine. But what if we're installing from source?
   what if we're not using pkg-config?
*/

#include "zmq.h"
#include <stdio.h>

int main() {
    fprintf(stdout, "%d\n%d\n%d\n", ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH);
    return 0;
}