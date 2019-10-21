#!/usr/bin/env ruby

## Ruby MOP Topics
### Structural Model
### Messaging
### Include/Extend mechanism

##################################
### Object is the root namespace.

Object.constants.map(&:to_s).grep(/Float/)

##################################
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

#- modules = B.ancestors
#- modules.inject({}){|h, m| h[m] = m.class; h}
#- modules.map{|m| [m, m.ancestors[1 .. -1]]}
#- modules.map{|m| [m, m.included_modules]}

#- A.ancestors.map{|m| [m, m.included_modules - m.ancestors[1 .. -1].flat_map(&:ancestors)]}

A.included_modules
Object.included_modules
### Module#included_modules is also transitive.

def direct_included_modules mod
  mod.included_modules - mod.ancestors[1 .. -1].flat_map{|m| m.included_modules}
end

direct_included_modules(A)
direct_included_modules(B)
direct_included_modules(Object)

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

#############################################################
### Includes are ordered:

module N
  def foo
    "N#foo"
  end
end

class G
  include N, M
end

G.ancestors
G.new.foo

#############################################################
### Methods are located through an object's class ancestors:

A.new.foo
B.new.foo
C.new.foo

def instance_methods_for_name mod, name
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

instance_methods_for_name(A, :foo)
instance_methods_for_name(B, :foo)
instance_methods_for_name(M, :foo)
instance_methods_for_name(C, :foo)

object = B.new
object.foo

# A method that only exists on object.
def object.foo
  "object.foo"
end

object.foo
object.method(:foo)

### Where does object.foo come from??
# It's not in here:
instance_methods_for_name(object.class, :foo)

## An Object's "eigenclass": a hidden class that holds "singleton" methods.
class Object
  def eigenclass
    class << self # <-- yup this is the syntax for it.
      self
    end
  end
end

object.eigenclass

instance_methods_for_name(object.eigenclass, :foo)

def methods_for_name obj, name
  instance_methods_for_name(obj.eigenclass, name) +
  instance_methods_for_name(obj.class,      name)
end

methods_for_name(B.new, :foo)
methods_for_name(object, :foo)

### How __send__ (kinda) works:

def my_send obj, sel, *args
  unbound_method = methods_for_name(obj, sel).first
  unbound_method.bind(obj).call(*args)
end

object = B.new
my_send(object, :foo) rescue "Nope"
def object.foo
  "object.foo"
end
my_send(object, :foo)

##################################
# Module#include, Object#extend:

module LogNewInstance
  def new *args
    super.tap do |obj|
      $stdout.puts "Created #{obj.inspect}"
      $stdout.flush
    end
  end
  
  def bar
    "N#bar"
  end
end

class D
  extend LogNewInstance
end

d = D.new
d.inspect
D.instance_methods(false)

## Where is #bar?
D.singleton_methods
D.singleton_methods.map{|n| D.method(n)}

## Modules contain instance methods added via extend.
LogNewInstance.instance_methods(false)

methods_for_name(D, :bar)

d.bar rescue "It ain't here!"
D.bar

######################################
# Modules as mixins.

module Formatting
  def format_to_10_chars x
    "%10s" % x.to_s
  end
end

class E
  include Formatting
end

E.new.format_to_10_chars(123)
Formatting.format_to_10_chars(456) rescue "It ain't here!"

methods_for_name(E, :format_to_10_chars)
methods_for_name(Formatting, :format_to_10_chars)
## Where are they?

Formatting.instance_methods - Object.methods

####################################
# Modules as functions AND mixins

module Formatting
  def format_to_10_chars x
    "%10s" % x.to_s
  end
  extend self # <=== What is this??
end

class E
  include Formatting
end

E.new.format_to_10_chars(123)
## Used as a mixin.

Formatting.format_to_10_chars(456)
## Used as a namespaced function.

Object.extend(Formatting).format_to_10_chars(789)
## Used as singleton methods.

methods_for_name(E, :format_to_10_chars)
methods_for_name(Formatting, :format_to_10_chars)

####################################
# Include callbacks.

module TrackIncludesAndExtends
  def self.included mod
    super
    THOSE_WHO_INCLUDED_ME << mod
  end
  THOSE_WHO_INCLUDED_ME = [ ]

  def self.extended mod
    super
    THOSE_WHO_EXTENDED_ME << mod
  end
  THOSE_WHO_EXTENDED_ME = [ ]
end

class F
  include TrackIncludesAndExtends
end
class G
  include TrackIncludesAndExtends
  extend  TrackIncludesAndExtends
end

TrackIncludesAndExtends::THOSE_WHO_INCLUDED_ME
TrackIncludesAndExtends::THOSE_WHO_EXTENDED_ME
