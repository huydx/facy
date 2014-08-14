class A
  def foo
    raise Exception.new
  rescue Exception => e
    p 'catch 1'
    begin
      raise Exception.new
    rescue Exception
      p 'catch 2'
    end
  rescue Exception => e
    p 'catch 2'
  end
end

A.new.foo
