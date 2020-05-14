# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_pyTupleTosplTuple.cgt

package Source_cpp;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Annotation; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeEvaluator; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::TupleValue; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   SPL::CodeGen::implementationPrologue($model);
   print "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '#include "splpy_sh.h"', "\n";
   print '#endif', "\n";
   print "\n";
   my $tkdir = $model->getContext()->getToolkitDirectory();
   my $pydir = $tkdir."/opt/python";
   
   require $pydir."/codegen/splpy.pm";
   
   # Initialize splpy.pm
   splpyInit($model);
   
   my $pyoutstyle = splpy_tuplestyle($model->getOutputPortAt(0));
   my $pywrapfunc='source_' . $pyoutstyle;
   my %cpp_tuple_types;
   print "\n";
   print "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR() :', "\n";
   print '    funcop_(NULL),', "\n";
   print '    pyOutNames_0(NULL),', "\n";
   print '    occ_(-1)', "\n";
   print '{', "\n";
   print '    const char * wrapfn = "';
   print $pywrapfunc;
   print '";', "\n";
   # If occ parameter is positive then pass-by-ref is possible
   # Generate code to allow pass by ref but only use when
   # not connected to a PE output port.
   
    my $oc = $model->getParameterByName("outputConnections");
   
    if ($oc) {
       my $occ = $oc->getValueAt(0)->getSPLExpression();
       if ($occ > 0) {
   print "\n";
   print "\n";
   print '    if (!this->getOutputPortAt(0).isConnectedToAPEOutputPort()) {', "\n";
   print '       // pass by reference', "\n";
   print '       wrapfn = "source_object";', "\n";
   print '       occ_ = ';
   print $occ;
   print ';', "\n";
   print '    }', "\n";
       } 
    }
   print "\n";
   print "\n";
   print '    funcop_ = new SplpyFuncOp(this, SPLPY_CALLABLE_STATE_HANDLER, wrapfn);', "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '  {', "\n";
   print '  SplpyGIL lock;', "\n";
   print '  pyOutNames_0 = Splpy::pyAttributeNames(getOutputPortAt(0));', "\n";
   print '  }', "\n";
   }
   print "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '   this->getContext().registerStateHandler(*this);', "\n";
   print '#endif', "\n";
   print '}', "\n";
   print "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::~MY_OPERATOR() ', "\n";
   print '{', "\n";
   print '    delete funcop_;', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::allPortsReady() ', "\n";
   print '{', "\n";
   print '  createThreads(1);', "\n";
   print '}', "\n";
   print ' ', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::prepareToShutdown() ', "\n";
   print '{', "\n";
   print '    funcop_->prepareToShutdown();', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(uint32_t idx)', "\n";
   print '{', "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '    SPL::ConsistentRegionContext *crc = static_cast<SPL::ConsistentRegionContext *>(getContext().getOptionalContext(CONSISTENT_REGION));', "\n";
   print '#endif', "\n";
   print "\n";
   print '    PyObject *pyReturnVar = NULL;', "\n";
   print "\n";
   print '    while(!getPE().getShutdownRequested()) {', "\n";
   print '        OPort0Type otuple;', "\n";
   print "\n";
   print '        bool submitTuple = false;', "\n";
   print '        bool allDone = false;', "\n";
   print "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '        ConsistentRegionPermit crp(crc);', "\n";
   print '#endif', "\n";
   print '        {', "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '            SPL::AutoMutex am(mutex_);', "\n";
   print '#endif', "\n";
   print '            try {', "\n";
   print '                SplpyGIL lock;', "\n";
   print '                Py_CLEAR(pyReturnVar);', "\n";
   print '                pyReturnVar = PyObject_CallObject(funcop_->callable(), NULL);', "\n";
   print "\n";
   print '                if (pyReturnVar == NULL) {', "\n";
   print '                    // Has the iteration completed?', "\n";
   print '                    if (PyErr_Occurred() == SplpyErrors::StopIteration)', "\n";
   print '                        allDone = true;', "\n";
   print '                    else', "\n";
   print '                        throw SplpyExceptionInfo::pythonError("source");', "\n";
   print '                }', "\n";
   print '                else if (SplpyGeneral::isNone(pyReturnVar)) {', "\n";
   print '                    Py_CLEAR(pyReturnVar);', "\n";
   print '                } else {', "\n";
   print '                    submitTuple = true;', "\n";
   print "\n";
    if ($pyoutstyle eq 'pickle') { 
   print "\n";
   print '                    if (occ_ > 0) {', "\n";
   print '                        // passing by reference', "\n";
   print '                        pyTupleByRef(otuple.get___spl_po(), pyReturnVar, occ_);', "\n";
   print '                        pyReturnVar = NULL;', "\n";
   print '                    } else {', "\n";
   print "\n";
   print '                        // Use the pointer of the pickled bytes object', "\n";
   print '                        // as the blob data so we need to maintain the', "\n";
   print '                        // reference count across the submit.', "\n";
   print '                        // We decrement it on the next loop iteration', "\n";
   print '                        // which is when we natually regain the lock.', "\n";
   print '                        pySplValueUsingPyObject(otuple.get___spl_po(), pyReturnVar);', "\n";
   print '                    }', "\n";
   }
   print "\n";
    if ($pyoutstyle eq 'string') { 
   print "\n";
   print '                    pySplValueFromPyObject(otuple.get_string(), pyReturnVar);', "\n";
   }
   print "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '                    if (PyTuple_Check(pyReturnVar)) {', "\n";
   print '                        fromPyTupleToSPLTuple(pyReturnVar, otuple);', "\n";
   print '                        //Py_DECREF(pyReturnVar); // causing trouble with multiple sources in same PE, why Py_DECREF when there is Py_CLEAR in the loop?', "\n";
   print '                    } else if (PyDict_Check(pyReturnVar)) {', "\n";
   print '                        fromPyDictToSPLTuple(pyReturnVar, otuple);', "\n";
   print '                        //Py_DECREF(pyReturnVar); // causing trouble with multiple sources in same PE, why Py_DECREF when there is Py_CLEAR in the loop?', "\n";
   print '                    } else {', "\n";
   print '                        throw SplpyGeneral::generalException("submit",', "\n";
   print '                "Fatal error: Value submitted must be a Python tuple or dict.");', "\n";
   print '                   }', "\n";
   }
   print "\n";
   print '               }', "\n";
   print '           } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '                SPLPY_OP_HANDLE_EXCEPTION_INFO_GIL(excInfo);', "\n";
   print '                continue;', "\n";
   print '           }', "\n";
   print '        }', "\n";
   print "\n";
   print '        if (submitTuple) {', "\n";
   print '            submit(otuple, 0);', "\n";
   print '        } else if (allDone) {', "\n";
   print "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '            // Wait until the region becomes consistent', "\n";
   print '            // before completing. If a reset occurred', "\n";
   print '            // then we need to continue the iterator which', "\n";
   print '            // might have been reset, and hence more tuples to submit.', "\n";
   print '            if (!crc->makeConsistent())', "\n";
   print '                continue;', "\n";
   print '#endif', "\n";
   print '            break;', "\n";
   print '        }', "\n";
   print '    }', "\n";
   print '}', "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
     # In this case we don't want the function that
     # converts the Python tuple to an SPL tuple to
     # copy attributes from the input port
     my $iport;
   
     my $oport = $model->getOutputPortAt(0);
     my $oport_submission = 0;
     my $otupleType = $oport->getSPLTupleType();
     my @onames = SPL::CodeGen::Type::getAttributeNames($otupleType);
     my @otypes = SPL::CodeGen::Type::getAttributeTypes($otupleType);
   
   print "\n";
   print '// Create member function that converts Python tuple to SPL tuple', "\n";
   # Generates functions in an operator that converts a Python
   # tuple to an SPL tuple for a given port and optional to
   # submit the tuple.
   #
   # $oport must be set on entry to required output port
   # $oport_submission must be set on entry to generate submission methods.
   # $iport can be set to automatically copy input attributes to
   # output attributes when the Python tuple does not supply a value.
   
     my $itypeparam = "";
     my $itypearg = "";
     if (defined $iport) {
        $itypeparam = ", " . $iport->getCppTupleType() . " const & ituple";
        $itypearg = ", ituple";
     }
   print "\n";
   print "\n";
    if ($oport_submission) { 
   print "\n";
   print ' ', "\n";
   print '// Python tuple to SPL tuple with submission to a port', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPythonToPort';
   print $oport->getIndex();
   print '(PyObject *pyTuple, ';
   print $oport->getCppTupleType();
   print ' & otuple ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  try {', "\n";
   print '    MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyTupleToSPLTuple(pyTuple, otuple ';
   print $itypearg;
   print ');', "\n";
   print '  } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '    SPLPY_OP_HANDLE_EXCEPTION_INFO(excInfo);', "\n";
   print '    return;', "\n";
   print '  }', "\n";
   print "\n";
   print '  STREAMSX_TUPLE_SUBMIT_ALLOW_THREADS(otuple, ';
   print $oport->getIndex();
   print ');', "\n";
   print '}', "\n";
   print "\n";
   print '// Python dict to SPL tuple with submission to a port.', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPythonDictToPort';
   print $oport->getIndex();
   print '(PyObject *pyDict, ';
   print $oport->getCppTupleType();
   print ' & otuple ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  try {', "\n";
   print '    MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyDictToSPLTuple(pyDict, otuple ';
   print $itypearg;
   print ');', "\n";
   print '  } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '    SPLPY_OP_HANDLE_EXCEPTION_INFO(excInfo);', "\n";
   print '    return;', "\n";
   print '  }', "\n";
   print "\n";
   print '  STREAMSX_TUPLE_SUBMIT_ALLOW_THREADS(otuple, ';
   print $oport->getIndex();
   print ');', "\n";
   print '}', "\n";
   print "\n";
   }
   print "\n";
   print "\n";
   # Ensure we generate function only once for each tuple type
   my $otype = $oport->getCppTupleType();
   if (! exists $cpp_tuple_types{$otype}) {
       $cpp_tuple_types{$otype} = 1;
   print "\n";
   print "\n";
   print '// Python tuple to SPL tuple , conversion only', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyTupleToSPLTuple(PyObject *pyTuple, ';
   print $oport->getCppTupleType();
   print ' & otuple  ';
   print $itypeparam;
   print ') {', "\n";
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
       
       # Only copy attributes across if they match on name and type,
       # or on name and input type T and output type optional<T>
       my $matchInputAttr = $iport->getAttributeByName($name);
       if (defined $matchInputAttr) {
           my $inputType = $matchInputAttr->getSPLType();
           if (($inputType eq $atype) ||
               (hasOptionalTypesSupport() &&
                SPL::CodeGen::Type::isOptional($atype) &&
                ($inputType eq
                 SPL::CodeGen::Type::getUnderlyingType($atype)))) {
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
   print '}', "\n";
   print "\n";
   print "\n";
   print '// Python dict to SPL tuple , conversion only', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyDictToSPLTuple(PyObject *pyDict, ';
   print $oport->getCppTupleType();
   print ' & otuple  ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  Py_ssize_t available = PyDict_Size(pyDict); ', "\n";
   print '    ', "\n";
     if (defined $iport) {
       print 'bool setAttr = false;';
     }
   
     for (my $ai = $oport->getNumberOfAttributes() - 1; $ai >= 0; --$ai) {
       
       my $attribute = $oport->getAttributeAt($ai);
       my $name = $attribute->getName();
       my $atype = $attribute->getSPLType();
       splToPythonConversionCheck($atype);
       
       if (defined $iport) {
                print 'setAttr = false;';
       }
   print "\n";
   print '    if (available > 0) {', "\n";
   print '         // Value from the Python function', "\n";
   print '         PyObject *pyAttrValue = PyDict_GetItem(pyDict, PyTuple_GET_ITEM(pyOutNames_';
   print $oport->getIndex();
   print ', ';
   print $ai;
   print '));', "\n";
   print '         if (pyAttrValue != NULL) {', "\n";
   print '             --available;', "\n";
   print '             if (!SplpyGeneral::isNone(pyAttrValue)) {', "\n";
   print '                  streamsx::topology::pySplValueFromPyObject(', "\n";
   print '                               otuple.get_';
   print $name;
   print '(), pyAttrValue);', "\n";
       if (defined $iport) {
                print 'setAttr = true;';
       }
   print "\n";
   print '           }', "\n";
   print '        }', "\n";
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
   print '}', "\n";
    } 
   print "\n";
   }
   print "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
