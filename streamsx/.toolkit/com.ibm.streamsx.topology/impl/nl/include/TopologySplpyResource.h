// This is a generated header.  Any modifications will be lost.
#ifndef NL_TOPOLOGYSPLPYRESOURCE_H
#define NL_TOPOLOGYSPLPYRESOURCE_H

#include <SPL/Runtime/Utility/FormattableMessage.h>

#define TOPOLOGY_LD_LIB_PATH(p0) \
   (::SPL::FormattableMessage1<typeof(p0)>("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0301I", "LD_LIBRARY_PATH={0}.", p0))

#define TOPOLOGY_LD_LIB_PATH_NO \
   (::SPL::FormattableMessage0("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0302I", "LD_LIBRARY_PATH not set."))

#define TOPOLOGY_LOAD_LIB(p0) \
   (::SPL::FormattableMessage1<typeof(p0)>("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0303I", "Loading Python library: {0}.", p0))

#define TOPOLOGY_LOAD_LIB_ERROR(p0) \
   (::SPL::FormattableMessage1<typeof(p0)>("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0304E", "Fatal error: could not open Python library: {0}.", p0))

#define TOPOLOGY_IMPORT_MODULE_ERROR(p0) \
   (::SPL::FormattableMessage1<typeof(p0)>("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0305E", "Fatal error: missing module: {0}.", p0))

#define TOPOLOGY_IMPORT_MODULE(p0) \
   (::SPL::FormattableMessage1<typeof(p0)>("com.ibm.streamsx.topology", "TopologySplpyResource", "en_US/TopologySplpyResource.xlf", "CDIST0306I", "Imported  module: {0}.", p0))

#endif  // NL_TOPOLOGYSPLPYRESOURCE_H
