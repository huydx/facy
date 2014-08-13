class String
  def colorize(*code)
    "\e[#{code.join(";")}m #{self} \e[0m" 
  end
end
