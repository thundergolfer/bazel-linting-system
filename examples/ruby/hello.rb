
# This shiny device says hello
class HelloWorld
  def initialize(name)
    @name = name.capitalize
  end
  def say_hi
    puts "Hello #{@name}!"
    puts "My name is Jono Belotti"
  end
end

hello = HelloWorld.new("World")
hello.say_hi