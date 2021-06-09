# @project Misc Ruby Utility
#
module Kernel
	# Add a warning suppression to kernel for code block.
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end
