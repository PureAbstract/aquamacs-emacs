if something_wrong?             # ruby-move-to-block-skips-heredoc
  ActiveSupport::Deprecation.warn(<<-eowarn)
  boo hoo
  end
  eowarn
end

# Percent literals.
b = %Q{This is a "string"}
c = %w!foo
 bar
 baz!
d = %(hello (nested) world)

# Don't propertize percent literals inside strings.
"(%s, %s)" % [123, 456]

# Or inside comments.
x = # "tot %q/to"; =
  y = 2 / 3

# Regexp after whitelisted method.
"abc".sub /b/, 'd'

# Don't mis-match "sub" at the end of words.
a = asub / aslb + bsub / bslb;

# Highlight the regexp after "if".
x = toto / foo if /do bar/ =~ "dobar"

bar(class: XXX) do              # ruby-indent-keyword-label
  foo
end
bar

foo = [1,                       # ruby-deep-indent
       2]

foo = {                         # ruby-deep-indent-disabled
  a: b
}

foo = { a: b,
        a1: b1
      }

foo({
     a: b,
     c: d
   })

foo = [                         # ruby-deep-indent-disabled
  1
]

foo(                            # ruby-deep-indent-disabled
  a
)

# Multiline regexp.
/bars
 tees # toots
 nfoos/

def test1(arg)
  puts "hello"
end

def test2 (arg)
  a = "apple"

  if a == 2
    puts "hello"
  else
    puts "there"
  end

  if a == 2 then
    puts "hello"
  elsif a == 3
    puts "hello3"
  elsif a == 3 then
    puts "hello3"
  else
    puts "there"
  end

  case a
  when "a"
    6
  # Support for this syntax was removed in Ruby 1.9, so we
  # probably don't need to handle it either.
  # when "b" :
  #   7
  # when "c" : 2
  when "d"  then 4
  else 5
  end
end

# Some Cucumber code:
Given /toto/ do
  print "hello"
end

# Bug#15208
if something == :==
  do_something
end

# Example from http://www.ruby-doc.org/docs/ProgrammingRuby/html/language.html
d = 4 + 5 +      # no '\' needed
    6 + 7

# Example from http://www.ruby-doc.org/docs/ProgrammingRuby/html/language.html
e = 8 + 9   \
    + 10         # '\' needed

begin
  foo
ensure
  bar
end

# Bug#15369
MSG = 'Separate every 3 digits in the integer portion of a number' \
      'with underscores(_).'

class C
  def foo
    self.end
    D.new.class
  end
end

a = foo(j, k) -
    bar_tee

while a < b do # "do" is optional
  foo
end

desc "foo foo" \
     "bar bar"

foo.
  bar

# https://github.com/rails/rails/blob/17f5d8e062909f1fcae25351834d8e89967b645e/activesupport/lib/active_support/time_with_zone.rb#L206
foo
  .bar

z = {
  foo: {
    a: "aaa",
    b: "bbb"
  }
}

foo if
  bar

if foo?
  bar
end

method arg1,                   # bug#15594
       method2 arg2,
               arg3

method? arg1,
        arg2

method! arg1,
        arg2

it "is a method call with block" do |asd|
  foo
end

it("is too!") {
  bar
}

and_this_one(has) { |block, parameters|
  tee
}

if foo &&
   bar
end

foo +
  bar

foo_bar_tee(1, 2, 3)
  .qux
  .bar

foo do
  bar
    .tee
end

def bar
  foo
    .baz
end

# Examples below still fail with `ruby-use-smie' on:

foo = [1, 2, 3].map do |i|
  i + 1
end

method !arg1,
       arg2

method [],
       arg2

method :foo,
       :bar

method (a + b),
       c

bar.foo do # "." is parent to "do"; it shouldn't be.
  bar
end
