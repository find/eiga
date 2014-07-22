%module math3d

%{
#include "math3d.h"
%}

%include "exception.i"

%exception {
  try {
    $action
  }
  SWIG_CATCH_STDEXCEPT
  catch (...) {
    SWIG_exception(SWIG_UnknownError, "unknown exception");
  }
}

%ignore mat3::m;
%ignore mat4::m;
%include "math3d.h"

