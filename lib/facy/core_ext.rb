class String
  def colorize(*code)
    "\e[#{code.join(";")}m#{self}\e[0m"
  end

  def short
    if self.size > 50
      self.truncate(50) + "..."
    else
      self
    end
  end
end
