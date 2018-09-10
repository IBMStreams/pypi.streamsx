# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_disallow_cr_trigger.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_enable_cr.cgt
# SPL_CGT_INCLUDE: ../pyspltuple.cgt

package Aggregate_h;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Annotation; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeEvaluator; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::TupleValue; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   print '/* Additional includes go here */', "\n";
   print '#include "splpy_funcop.h"', "\n";
   print '#include <SPL/Runtime/Window/Window.h>', "\n";
   print "\n";
   print 'using namespace streamsx::topology;', "\n";
   print "\n";
   SPL::CodeGen::headerPrologue($model);
   print "\n";
   print "\n";
    # Python operators generally may be included in a consistent region, and
    # may be the source operator in a consistent region, but may not be the 
    # source operator in a consistent-region configured with an operator-driven
    # trigger.  This is because we currently do not support any way for a python
    # operator to trigger a consistent region drain cycle.  This file enforces
    # this rule at compile time, and should be @included in any python operator
    # unless it is designed to support triggering a consistent region.
   
   
    my $consistentRegionContext = $model->getContext()->getOptionalContext("ConsistentRegion");
    if ($consistentRegionContext && $consistentRegionContext->isTriggerOperator()) { 
      # TODO
      # For topology operators, the source location here is unhelpful, since
      # it refers to a location in a generated file that the user generally
      # cannot see.  It would be better to read the @spl_note containing
      # the original python source location and report that.
      SPL::CodeGen::exitln("The " . $model->getContext()->getClass() . " operator may not be a trigger operator for a consistent region.", $model->getContext()->getSourceLocation());
   }  
   print "\n";
   print "\n";
   # Configure Windowing
    my $inputPort = $model->getInputPortAt(0); 
    my $window = $inputPort->getWindow();
    my $windowCppType = SPL::CodeGen::getWindowCppType($window,"PyObject *");
   print "\n";
   print "\n";
    # Generic setup of a variety of variables to
    # handle conversion of spl tuples to/from Python
   
    my $tkdir = $model->getContext()->getToolkitDirectory();
    my $pydir = $tkdir."/opt/python";
   
    require $pydir."/codegen/splpy.pm";
   
    # Initialize splpy.pm
    splpyInit($model);
   
    # Currently function operators only have a single input port
    # and take all the input attributes
    my $iport = $model->getInputPortAt(0);
    my $inputAttrs2Py = $iport->getNumberOfAttributes();
   
    # determine which input tuple style is being used
    my $pystyle = $model->getParameterByName("pyStyle");
    if ($pystyle) {
        $pystyle = substr($pystyle->getValueAt(0)->getSPLExpression(), 1, -1);
    } else {
        $pystyle = splpy_tuplestyle($model->getInputPortAt(0));
    }
    # $pystyle is the raw value from the operator parameter
    # $pystyle_nt is the value that defines how the function is called
    # (for style namedtuple:xxxx it is tuple)
    # $pystyle_nt is non-zero if style is namedtuple
    my $pystyle_fn = $pystyle;
    my $pystyle_nt = substr($pystyle, 0, 11) eq 'namedtuple:';
    if ($pystyle_nt) {
       $pystyle_fn = 'tuple';
    }
   print "\n";
   print 'class MY_OPERATOR : public MY_BASE_OPERATOR,', "\n";
   print '      public WindowEvent<PyObject *>,', "\n";
   print '      public DelegatingStateHandler', "\n";
   print '{', "\n";
   print 'public:', "\n";
   print '  // Constructor', "\n";
   print '  MY_OPERATOR();', "\n";
   print "\n";
   print '  // Destructor', "\n";
   print '  virtual ~MY_OPERATOR(); ', "\n";
   print "\n";
   print '  // Notify termination', "\n";
   print '  void prepareToShutdown(); ', "\n";
   print "\n";
   print '  // Tuple processing for non-mutating ports', "\n";
   print '  void process(Tuple const & tuple, uint32_t port);', "\n";
   print '  void process(Punctuation const & punct, uint32_t port);', "\n";
   print "\n";
   print '  // Window', "\n";
   print '  void onWindowTriggerEvent(', "\n";
   print '     Window<PyObject *> & window, Window<PyObject *>::PartitionType const& key);', "\n";
   print "\n";
   print '  void beforeWindowFlushEvent(', "\n";
   print '     Window<PyObject *> & window, Window<PyObject *>::PartitionType const& key) {', "\n";
   print "\n";
   print '     onWindowTriggerEvent(window, key);', "\n";
   print '  }', "\n";
   print '  ', "\n";
   print 'void afterTupleEvictionEvent(', "\n";
   print '     Window<PyObject *> & window,  Window<PyObject *>::TupleType & tuple,', "\n";
   print '     Window<PyObject *>::PartitionType const & partition);', "\n";
   print "\n";
   print 'protected:', "\n";
   print '  virtual void checkpointExtra(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void resetExtra(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void resetToInitialStateExtra();', "\n";
   print "\n";
   print 'private:', "\n";
   print '    SplpyOp * op() { return funcop_; }', "\n";
   print "\n";
   print '    // Members', "\n";
   print '    // Control for interaction with Python', "\n";
   print '    SplpyFuncOp *funcop_;', "\n";
   print '    PyObject *spl_in_object_out;', "\n";
   print '    ', "\n";
   print '    PyObject *pyInStyleObj_;', "\n";
   print "\n";
   print '    PyObject *loads;', "\n";
   print "\n";
   print '    // Number of output connections when passing by ref', "\n";
   print '    // -1 when cannot pass by ref', "\n";
   print '    int32_t occ_;', "\n";
   print "\n";
   print '    // Window definition', "\n";
   print '    ';
   print $windowCppType;
   print '  window_;	       ', "\n";
   print "\n";
    
    # Enable or disable checkpointing, including support for the necessary locking.
   
    # Checkpointing should be enabled if the operator is in a consistent region,
    # or has checkpointing configured.  Also, the operator must be stateful,
    # otherwise no checkpointing is needed.
   
    # This will generally be @included in the declaration of an SPL operator
    # template.  It create static const values indicating whether the operator
    # instance is in a consistent region, and whether it is checkpointing.
    # It also provides some typedefs for types to be used by the operator
    # to support checkpointing and consistent region.
   
    my $isInConsistentRegion = $model->getContext()->getOptionalContext("ConsistentRegion");
    my $ckptKind = $model->getContext()->getCheckpointingKind();
    my $pyStateful = $model->getParameterByName("pyStateful");
    my $stateful = 0;
    if (defined($pyStateful)) {
      $stateful = $pyStateful->getValueAt(0)->getSPLExpression() eq "true";
    }
    else {
      # no pyStateful parameter.  Try calling splpy_OperatorCallable().
      if (defined &splpy_OperatorCallable) {
        $stateful = splpy_OperatorCallable() eq 'class'
      }
    }
   
    my $isCheckpointing = $stateful && ($isInConsistentRegion or $ckptKind ne "none");
   print "\n";
   print '  // True if this operator is in a consistent region.', "\n";
   print '  static const bool isInConsistentRegion = ';
   print  $isInConsistentRegion ? "true" :" false" ;
   print ';', "\n";
   print '  // True if operator is stateful and checkpoint is enabled, ', "\n";
   print '  // whether directly or through consistent region.', "\n";
   print '  static const bool isCheckpointing = ';
   print $isCheckpointing ? "true" : "false" ;
   print ';', "\n";
   print "\n";
   print '  typedef OptionalConsistentRegionContextImpl<isInConsistentRegion> OptionalConsistentRegionContext;', "\n";
   print '  typedef OptionalConsistentRegionContext::Permit AutoConsistentRegionPermit;', "\n";
   print '  typedef OptionalAutoLockImpl<isCheckpointing> OptionalAutoLock;', "\n";
   print "\n";
   print "\n";
   print '    OptionalConsistentRegionContext crContext;', "\n";
   print '}; ', "\n";
   print "\n";
   SPL::CodeGen::headerEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
