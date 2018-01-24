# SPL_CGT_INCLUDE: ../pyspltuple2dict.cgt
# SPL_CGT_INCLUDE: ../pyspltuple.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_splTupleCheckForBlobs.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2value.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2tuple.cgt

package Aggregate_cpp;
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
   print "\n";
   
   # Configure Windowing
    my $inputPort = $model->getInputPortAt(0); 
    my $window = $inputPort->getWindow();
    my $windowCppInitializer = SPL::CodeGen::getWindowCppInitializer($window,"PyObject *");
   
    # Select the Python wrapper function
    my $pyoutstyle = splpy_tuplestyle($model->getOutputPortAt(0));
   
    if (($pystyle eq 'dict') || ($pyoutstyle eq 'dict') || ($pystyle eq 'tuple')) {
       SPL::CodeGen::exitln("Dictionary input and output not supported.");
    }
    
    my $out_pywrapfunc=  'object_in__' . $pyoutstyle . '_out';
   print "\n";
   print "\n";
   print '#define SPLPY_AGGREGATE(f, v, r, occ) \\', "\n";
   print '    streamsx::topology::Splpy::pyTupleMap(f, v, r)', "\n";
   print "\n";
   print '// Constructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR() :', "\n";
   print '   funcop_(NULL),', "\n";
   print '   pyInNames_(NULL),', "\n";
   print '   loads(NULL),', "\n";
   print '   occ_(-1),', "\n";
   print '   window_(';
   print $windowCppInitializer;
   print ')', "\n";
   print '{', "\n";
   print '    window_.registerOnWindowTriggerHandler(this);', "\n";
   print '    window_.registerAfterTupleEvictionHandler(this);', "\n";
   print "\n";
   print '    const char * out_wrapfn = "';
   print $out_pywrapfunc;
   print '";', "\n";
   # If occ parameter is positive then pass-by-ref is possible
   # Generate code to allow pass by ref but only use when
   # not connected to a PE output port.
   
    my $oc = $model->getParameterByName("outputConnections");
   
    if ($oc) {
       my $occ = $oc->getValueAt(0)->getSPLExpression();
       if ($occ > 0) {
           my $pybyrefwrapfunc = 'object_in__object_out';
   print "\n";
   print "\n";
   print '#undef SPLPY_AGGREGATE', "\n";
   print '#define SPLPY_AGGREGATE(f, v, r, occ) \\', "\n";
   print '    streamsx::topology::Splpy::pyTupleMapByRef(f, v, r, occ)', "\n";
   print "\n";
   print '    if (!this->getOutputPortAt(0).isConnectedToAPEOutputPort()) {', "\n";
   print '       // pass by reference', "\n";
   print '       out_wrapfn = "';
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
   print '    funcop_ = new SplpyFuncOp(this, out_wrapfn);', "\n";
   print '    ', "\n";
   print '    // Obtain the function that loads the tuple\'s value in process()', "\n";
   print '    {', "\n";
   print '    SplpyGIL lock;', "\n";
   print '    ';
   if ($pystyle eq 'pickle'){
   print "\n";
   print '    loads = SplpyGeneral::loadFunction("pickle", "loads");', "\n";
   print '    ';
    } elsif ($pystyle eq 'json'){ 
   print "\n";
   print '    loads = SplpyGeneral::loadFunction("json", "loads");', "\n";
   print '    ';
    } 
   print "\n";
   print '    }', "\n";
   print "\n";
   print '}', "\n";
   print "\n";
   print '// Destructor', "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::~MY_OPERATOR() ', "\n";
   print '{', "\n";
   print '  delete funcop_;', "\n";
   print "\n";
   print '  ';
    if (($pystyle eq 'json') || ($pystyle eq 'pickle')) {
   print "\n";
   print '  {', "\n";
   print '      SplpyGIL lock;', "\n";
   print '      if (loads != NULL){', "\n";
   print '      	 Py_DECREF(loads);', "\n";
   print '      }', "\n";
   print '  }', "\n";
   print '  ';
    } 
   print "\n";
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
   print '  PyObject *python_value;', "\n";
   print "\n";
   print '  // If the input style is pickle,', "\n";
   print "\n";
   print '  // None of the streamsx::topology methods in this scope grab the lock', "\n";
   print '  // so we need to do it here.', "\n";
   print '  ', "\n";
   print '  ';
   if ($pystyle eq 'pickle'){
   print "\n";
   print "\n";
   print '      unsigned char const *data = value.getData();', "\n";
   print '      unsigned char fmt = *data;', "\n";
   print '      if (fmt == STREAMSX_TPP_PTR) {', "\n";
   print '          __SPLTuplePyPtr *stp = (__SPLTuplePyPtr *)(data);', "\n";
   print '          python_value = stp->pyptr;', "\n";
   print '      }', "\n";
   print '      // Anything ASCII is also Pickle (Python 2 default format)', "\n";
   print '      else if (fmt <= STREAMSX_TPP_PICKLE) {', "\n";
   print '      	  // This is a pickled value. Need to depickle it.', "\n";
   print '	  {', "\n";
   print '	      SplpyGIL lock; ', "\n";
   print '              python_value = pySplValueToPyObject(value);', "\n";
   print "\n";
   print '	      // Depickle the tuple.', "\n";
   print '	      PyObject *tup = PyTuple_New(1);', "\n";
   print '	      PyTuple_SET_ITEM(tup, 0, python_value);', "\n";
   print '   	      python_value = SplpyGeneral::pyCallObject(loads, tup);', "\n";
   print "\n";
   print '	  } // End SplpyGIL lock', "\n";
   print '      }', "\n";
   print '  ';
    } elsif ($pystyle eq 'string'){
   print "\n";
   print '      {', "\n";
   print '	  SplpyGIL lock;', "\n";
   print '          python_value = pySplValueToPyObject(value);', "\n";
   print '      }', "\n";
   print '  ';
    } elsif ($pystyle eq 'json'){
   print "\n";
   print '      {', "\n";
   print '      	  SplpyGIL lock;', "\n";
   print '          python_value = pySplValueToPyObject(value);', "\n";
   print '	  PyObject *tup = PyTuple_New(1);', "\n";
   print '	  PyTuple_SET_ITEM(tup, 0, python_value);', "\n";
   print '	  python_value = SplpyGeneral::pyCallObject(loads, tup);', "\n";
   print '      }', "\n";
   print '  ', "\n";
   print ' ';
    } else{
   	  SPL::CodeGen::exitln($pystyle . " is an unsupported input type.");      
       }
    
   print "\n";
   print "\n";
   print "\n";
   print '  window_.insert(python_value);', "\n";
   print '}', "\n";
   print "\n";
   print "\n";
   print '// ##############################', "\n";
   print '// Window Event Handler Overrides', "\n";
   print '// ##############################', "\n";
   print "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::afterTupleEvictionEvent(', "\n";
   print '     Window<PyObject *> & window,  Window<PyObject *>::TupleType & tuple,  Window<PyObject *>::PartitionType const & partition) {', "\n";
   print '     // Drop reference to tuple after it is removed from the window.', "\n";
   print '     SplpyGIL lock;', "\n";
   print '     Py_DECREF(tuple);', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::onWindowTriggerEvent(Window<PyObject *> & window, Window<PyObject *>::PartitionType const & key){    ', "\n";
   print '    Window<PyObject *>::StorageType & storage = window.getWindowStorage();', "\n";
   print "\n";
   print '    Window<PyObject *>::DataType & content = storage[key];', "\n";
   print '    PyObject *items;', "\n";
   print '    {', "\n";
   print '    SplpyGIL lock;', "\n";
   print '    items = PyList_New(std::distance(content.begin(), content.end()));', "\n";
   print '    unsigned int idx = 0;', "\n";
   print '    for(WindowType::DataType::iterator it=content.begin(); it!=content.end(); ++it) {', "\n";
   print '        PyObject *item = *it;', "\n";
   print '	// The tuple steals a reference, increment such that the window can maintain a copy', "\n";
   print '	// once the tuple is deleted.', "\n";
   print '	Py_INCREF(item);', "\n";
   print '	PyList_SET_ITEM(items, idx, item);', "\n";
   print '	++idx;', "\n";
   print '    }', "\n";
   print '    }', "\n";
   print '    PyObject *value = items;', "\n";
   print '  OPort0Type otuple;', "\n";
   print "\n";
   print '  ', "\n";
   print '  if (SPLPY_AGGREGATE(funcop_->callable(), value,', "\n";
   print '       otuple.get_';
   print $model->getOutputPortAt(0)->getAttributeAt(0)->getName();
   print '(), occ_)){  ', "\n";
   print '     submit(otuple, 0);', "\n";
   print '  }', "\n";
   print '  submit(Punctuation::WindowMarker, 0);', "\n";
   print '}', "\n";
   print "\n";
   print '// ##################################', "\n";
   print '// End Window Event Handler Overrides', "\n";
   print '// ##################################', "\n";
   print "\n";
   print "\n";
   print 'namespace SPL{', "\n";
   print '    Checkpoint & operator <<(Checkpoint &ostr, const PyObject  & obj){', "\n";
   print '        return ostr;', "\n";
   print '    }', "\n";
   print "\n";
   print '    Checkpoint & operator >>(Checkpoint &ostr, const PyObject  & obj){', "\n";
   print '        return ostr;', "\n";
   print '    }', "\n";
   print "\n";
   print '    ByteBuffer<Checkpoint> & operator<<(ByteBuffer<Checkpoint> & ckpt, PyObject * obj){', "\n";
   print '        return ckpt;', "\n";
   print '    }', "\n";
   print "\n";
   print "\n";
   print '    ByteBuffer<Checkpoint> & operator>>(ByteBuffer<Checkpoint> & ckpt, PyObject * obj){', "\n";
   print '        return ckpt;', "\n";
   print '    }', "\n";
   print "\n";
   print ' }', "\n";
   print "\n";
   print 'std::ostream & operator <<(std::ostream &ostr, const PyObject  & obj){', "\n";
   print '    return ostr;', "\n";
   print '}', "\n";
   print "\n";
   print 'std::ostream & operator >>(std::ostream &ostr, const PyObject  & obj){', "\n";
   print '    return ostr;', "\n";
   print '}', "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
