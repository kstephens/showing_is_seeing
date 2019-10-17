#!/usr/bin/env ruby

### Some Classes:

class A
  def foo
    "A#foo"
  end
end

class B < A
  def foo
    "B#foo"
  end
end

B.superclass
A.superclass

##################################
### An Object has a Class.
### A Class is a Module.
### A Module is an Object.

A.class

A.class.superclass

A.class.superclass.superclass

A.class.superclass.superclass.superclass

A.class.superclass.superclass.superclass.superclass

##################################
### Respect your ancestors:

A.ancestors
B.ancestors

### Uhh.  Where did Kernel come from?

Object.ancestors
## Module#ancestors is transitive.

#! modules = B.ancestors
#! modules.inject({}){|h, m| h[m] = m.class; h}
#! modules.map{|m| [m, m.ancestors[1 .. -1]]}
#! modules.map{|m| [m, m.included_modules]}

#! A.ancestors.map{|m| [m, m.included_modules - m.ancestors[1 .. -1].flat_map(&:ancestors)]}

### Module#included_modules is also transitive.
A.included_modules
Object.included_modules

class Module
  def direct_included_modules
    included_modules - ancestors[1 .. -1].flat_map{|m| m.included_modules}
  end
end

A.direct_included_modules
B.direct_included_modules
Object.direct_included_modules

###########################################
### Classes and the Modules they Love:

module M
  def foo
    "M#foo"
  end
end

M.ancestors

class C < A
  include M
end

C.ancestors

### Methods are searched from object's class through its ancestors:

def all_methods_named mod, name
  mod.
  ancestors.
  flat_map do |mod|
    mod.
    instance_methods(false).        # <= a sequence of method names NOT inherited.
    map do |m_name|
      mod.instance_method(m_name)   # <= an UnboundMethod
    end
  end.
  select{|meth| meth.name == name}
end

A.new.foo
all_methods_named(A, :foo)
B.new.foo
all_methods_named(B, :foo)
C.new.foo
all_methods_named(C, :foo)
all_methods_named(M, :foo)

object = B.new
object.foo

# A method that only exists on object.
def object.foo
  "object.foo"
end

object.foo
object.method(:foo)

### Where does object.foo come from??

all_methods_named(object.class, :foo)

## The eignenclass is a hidden class that contains "singleton" methods.
class Object
  def eigenclass
    class << self # <-- yup this is the syntax for it.
      self
    end
  end
end

object.eigenclass
object.eigenclass

all_methods_named(object.eigenclass, :foo)

def really_all_methods_named obj, name
  all_methods_named(obj.eigenclass, name) + all_methods_named(obj.class, name)
end

really_all_methods_named(B.new, :foo)
really_all_methods_named(object, :foo)

### How __send__ works:

def my_send obj, sel, *args
  unbound_method = really_all_methods_named(obj, sel).first
  unbound_method.bind(obj).call(*args)
end

my_send(object, :foo)

