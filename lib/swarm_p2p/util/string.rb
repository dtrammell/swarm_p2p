# @project Misc Ruby Utility
#
class String
  # Underscore a string such that camelcase, dashes and spaces are
  # replaced by underscores. This is the reverse of {#camelcase},
  # albeit not an exact inverse.
  #
  #   "SnakeCase".snakecase         #=> "snake_case"
  #   "Snake-Case".snakecase        #=> "snake_case"
  #   "Snake Case".snakecase        #=> "snake_case"
  #   "Snake  -  Case".snakecase    #=> "snake_case"
  #
  # Note, this method no longer converts `::` to `/`, in that case
  # use the {#pathize} method instead.
  # TODO: Add *separators to #snakecase, like camelcase.
	#
  def snakecase
    #gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr('-', '_').
    gsub(/\s/, '_').
    gsub(/__+/, '_').
    downcase
  end

  alias_method :underscore, :snakecase

	# Return ruby object named in a string.
  # s = "Socket".constantize
	# puts s.name # Prints "Socket"
	# puts s.class # Prints "Class"
  def constantize
    return self.to_s.split('::').reduce(Module){ |m, c| m.const_get(c) }
  end

end

