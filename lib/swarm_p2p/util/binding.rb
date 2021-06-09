# @project Misc Ruby Utility
# @author Donovan A.
#
# IRB Binding monkey patch to remove annoying print of code...
#
class Binding
  def irb
	  IRB.setup(source_location[0], argv: [])
	  workspace = IRB::WorkSpace.new(self)
	  binding_irb = IRB::Irb.new(workspace)
	  binding_irb.context.irb_path = File.expand_path(source_location[0])
	  binding_irb.run(IRB.conf)
	end
end
