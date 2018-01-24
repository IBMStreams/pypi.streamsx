# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_pyTupleTosplTuple.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2dict.cgt
# SPL_CGT_INCLUDE: ../pyspltuple.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_splTupleCheckForBlobs.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2value.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2tuple.cgt

package Map_cpp;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Annotation; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeEvaluator; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::TupleValue; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   print '/* Additional includes go here */', "\n";
   print "\n";
   print '#include "splpy.h"', "\n";
   print '#include "splpy_funcop.h"', "\n";
   print "\n";
   print 'using namespace streamsx::topology;', "\n";
   print "\n";
   SPL::CodeGen::implementationPrologue($model);
   print "\n";
   print "\n";
    # Generic setup of a variety of variables to
    # handle conversion of spl tuples to/from Python
   
    my $tkdir = $model->getContext()->getToolkitDirectory();
    my $pydir = $tkdir."/opt/python";
   
    require $pydir."/codegen/splpy.pm";
   
    # Currently function operators only have a single input port
    # and take all the input attributes
    my $iport = $model->getInputPortAt(0);
    my $inputAttrs2Py = $iport->getNumberOfAttributes();
   
    # determine which input tuple style is being used
   
    my $pystyle = $model->getParameterByName("pyStyle");
    if ($pystyle) {
        $pystyle = substr $pystyle->getValueAt(0)->getSPLExpression(), 1, -1;
    } else {
        $pystyle = splpy_tuplestyle($model->getInputPortAt(0));
    }
   print "\n";
   print "\n";
    # Select the Python wrapper function
    my $pyoutstyle = splpy_tuplestyle($model->getOutputPortAt(0));
    my $pywrapfunc= $pystyle . '_in__' . $pyoutstyle . '_out';
   print "\n";
   print "\n";
   print '#define SPLPY_TUPLE_MAP(f, v, r, occ) \\', "\n";
   print '    streamsx::topology::Splpy::pyTupleMap(f, v, r)', "\n";
   print "\n";
   print '// Constructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR() :', "\n";
   print '   funcop_(NULL),', "\n";
   print '   pyInNames_(NULL),', "\n";
   print '   occ_(-1)', "\n";
   print '{', "\n";
   print '    const char * wrapfn = "';
   print $pywrapfunc;
   print '";', "\n";
   print "\n";
   # If occ parameter is positive then pass-by-ref is possible
   # Generate code to allow pass by ref but only use when
   # not connected to a PE output port.
   
    my $oc = $model->getParameterByName("outputConnections");
   
    if ($oc) {
       my $occ = $oc->getValueAt(0)->getSPLExpression();
       if ($occ > 0) {
           my $pybyrefwrapfunc = $pystyle . '_in__object_out';
   print "\n";
   print "\n";
   print '#undef SPLPY_TUPLE_MAP', "\n";
   print '#define SPLPY_TUPLE_MAP(f, v, r, occ) \\', "\n";
   print '    streamsx::topology::Splpy::pyTupleMapByRef(f, v, r, occ)', "\n";
   print "\n";
   print '    if (!this->getOutputPortAt(0).isConnectedToAPEOutputPort()) {', "\n";
   print '       // pass by reference', "\n";
   print '       wrapfn = "';
   print $pybyrefwrapfunc;
   print '";', "\n";
   print '       occ_ = ';
   print $occ;
   print ';', "\n";
   print '    }', "\n";
       } 
    }
   print "\n";
   print "\n";
   print '    funcop_ = new SplpyFuncOp(this, wrapfn);', "\n";
   print "\n";
    if ($pystyle eq 'dict') { 
   print "\n";
   print '     SplpyGIL lock;', "\n";
   print '     pyInNames_ = streamsx::topology::Splpy::pyAttributeNames(', "\n";
   print '               getInputPortAt(0));', "\n";
    } 
   print "\n";
   print '}', "\n";
   print "\n";
   print '// Destructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::~MY_OPERATOR() ', "\n";
   print '{', "\n";
    if ($pystyle eq 'dict') { 
   print "\n";
   print '    if (pyInNames_) {', "\n";
   print '      SplpyGIL lock;', "\n";
   print '      Py_DECREF(pyInNames_);', "\n";
   print '    }', "\n";
    } 
   print "\n";
   print "\n";
   print '  delete funcop_;', "\n";
   print '}', "\n";
   print "\n";
   print '// Notify pending shutdown', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::prepareToShutdown() ', "\n";
   print '{', "\n";
   print '    funcop_->prepareToShutdown();', "\n";
   print '}', "\n";
   print "\n";
   print '// Tuple processing for non-mutating ports', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Tuple const & tuple, uint32_t port)', "\n";
   print '{', "\n";
   # Takes the input SPL tuple and converts it to
   # the arguments needed to be passed to a Python
   # functional operator
   
   # Variables that need to be set:
   
   # $pyStyle - tuple or dictionary
   # $iport - input port 
   # $inputAttrs2Py - number of attributes to pass as tuple style
   print "\n";
   print "\n";
   print '    ';
   print $iport->getCppTupleType();
   print ' const & ';
   print $iport->getCppTupleName();
   print ' = static_cast< ';
   print $iport->getCppTupleType();
   print ' const &>(tuple);', "\n";
   print "\n";
   print splpy_inputtuple2value($pystyle, $iport);
   
   if ($pystyle eq 'dict' || $pystyle eq 'tuple') {
   print "\n";
   # Perl Variables that need to be set:
   #
   # $iport - input port 
   #
   # $inputAttrs2Py - number of attributes to pass as tuple style
   #
   
      #Check if a blob exists in the input schema
      for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
         if (typeHasBlobs($iport->getAttributeAt($i)->getSPLType())) {
   print "\n";
   print '   PYSPL_MEMORY_VIEW_CLEANUP();', "\n";
            last;
         }
      }
   print "\n";
   }
   
   if ($pystyle eq 'dict') {
   print "\n";
   # Takes the input SPL tuple and converts it to
   # as a dict to be passed to a Python functional operator
   #
   # Leaves the C++ variable value set to a PyObject * dict.
   
   # Variables that need to be set:
   # $iport - input port 
   print "\n";
   print "\n";
   print '  PyObject *value = 0;', "\n";
   print '  {', "\n";
   print '  SplpyGIL lockdict;', "\n";
   print '  PyObject * pyDict = PyDict_New();', "\n";
        for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
            my $la = $iport->getAttributeAt($i);
            print convertAndAddToPythonDictionaryObject($iport->getCppTupleName(), $i, $la->getSPLType(), $la->getName(), 'pyInNames_');
        }
   print "\n";
   print '  value = pyDict;', "\n";
   print '  }', "\n";
    } elsif ($pystyle eq 'tuple') { 
   print "\n";
   # Takes the input SPL tuple and converts it to
   # as a tuple to be passed to a Python functional operator
   #
   # Leaves the C++ variable value set to a PyObject * tuple.
   
   # Variables that need to be set:
   # $iport - input port 
   print "\n";
   print "\n";
   print '  PyObject *value = 0;', "\n";
   print '  {', "\n";
   print '  SplpyGIL locktuple;', "\n";
   print '  PyObject * pyTuple = PyTuple_New(';
   print $inputAttrs2Py;
   print ');', "\n";
        for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
            my $la = $iport->getAttributeAt($i);
            print convertAndAddToPythonTupleObject($iport->getCppTupleName(), $i, $la->getSPLType(), $la->getName());
        }
   print "\n";
   print '  value = pyTuple;', "\n";
   print '  }', "\n";
    } 
   print "\n";
   print "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '  {', "\n";
   print '  SplpyGIL lock;', "\n";
   print '  PyObject * ret = streamsx::topology::Splpy::pyTupleMap(funcop_->callable(), value);', "\n";
   print '  if (ret == NULL)', "\n";
   print '     return;', "\n";
   print '  fromPythonToPort0(ret);', "\n";
   print '  Py_DECREF(ret);', "\n";
   print '  }', "\n";
   print '  ', "\n";
    } else { 
   print "\n";
   print '  OPort0Type otuple;', "\n";
   print "\n";
   print '  if (SPLPY_TUPLE_MAP(funcop_->callable(), value,', "\n";
   print '       otuple.get_';
   print $model->getOutputPortAt(0)->getAttributeAt(0)->getName();
   print '(), occ_))', "\n";
   print '     submit(otuple, 0);', "\n";
   print "\n";
   }
   print "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Punctuation const & punct, uint32_t port)', "\n";
   print '{', "\n";
   print '   forwardWindowPunctuation(punct);', "\n";
   print '}', "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
     # In this case we don't want the function that
     # converts the Python tuple to an SPL tuple to
     # copy attributes from the input port
     my $iport;
   
     my $oport = $model->getOutputPortAt(0);
     my $otupleType = $oport->getSPLTupleType();
     my @onames = SPL::CodeGen::Type::getAttributeNames($otupleType);
     my @otypes = SPL::CodeGen::Type::getAttributeTypes($otupleType);
   
   print "\n";
   print '// Create member function that converts Python tuple to SPL tuple', "\n";
   # Generates a function in an operator that converts a Python
   # tuple to an SPL tuple for a given port.
   #
   # $oport must be set on entry to required output port
   # $iport can be set to automatically copy input attributes to
   # output attributes when the Python tuple does not supply a value.
   
     my $itypeparam = "";
     if (defined $iport) {
        $itypeparam = ", " . $iport->getCppTupleType() . " const & ituple";
     }
   print "\n";
   print ' ', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPythonToPort';
   print $oport->getIndex();
   print '(PyObject *pyTuple ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  ';
   print $oport->getCppTupleType();
   print ' otuple;', "\n";
   print "\n";
   print '  Py_ssize_t frs = PyTuple_GET_SIZE(pyTuple); ', "\n";
   print '    ', "\n";
     if (defined $iport) {
       print 'bool setAttr = false;';
     }
   
     for (my $ai = 0; $ai < $oport->getNumberOfAttributes(); ++$ai) {
       
       my $attribute = $oport->getAttributeAt($ai);
       my $name = $attribute->getName();
       my $atype = $attribute->getSPLType();
       splToPythonConversionCheck($atype);
       
       if (defined $iport) {
                print 'setAttr = false;';
       }
   print "\n";
   print '    if (';
   print $ai;
   print ' < frs) {', "\n";
   print '         // Value from the Python function', "\n";
   print '         PyObject *pyAttrValue = PyTuple_GET_ITEM(pyTuple, ';
   print $ai;
   print ');', "\n";
   print '         if (!SplpyGeneral::isNone(pyAttrValue)) {', "\n";
   print '                  streamsx::topology::pySplValueFromPyObject(', "\n";
   print '                               otuple.get_';
   print $name;
   print '(), pyAttrValue);', "\n";
       if (defined $iport) {
                print 'setAttr = true;';
       }
   print "\n";
   print '      }', "\n";
   print '   }', "\n";
       if (defined $iport) {
       
       # Only copy attributes across if they match on name and type
       my $matchInputAttr = $iport->getAttributeByName($name);
       if (defined $matchInputAttr) {
          if ($matchInputAttr->getSPLType() eq $attribute->getSPLType()) {
   print "\n";
   print '    if (!setAttr) {', "\n";
   print '      // value from the input attribute', "\n";
   print '      otuple.set_';
   print $name;
   print '(ituple.get_';
   print $name;
   print '());', "\n";
   print '    }', "\n";
         }
       }
      }
   print "\n";
   print '         ', "\n";
   }
    
   print "\n";
   print "\n";
   print '  Py_BEGIN_ALLOW_THREADS', "\n";
   print '  submit(otuple, ';
   print $oport->getIndex();
   print ');', "\n";
   print '  Py_END_ALLOW_THREADS', "\n";
   print '}', "\n";
   }
   print "\n";
   print "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
