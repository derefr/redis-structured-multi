Gem::Specification.new do |s|
  s.name = %q{redis-structured-multi}
  s.version = "0.0.1"
  s.date = %q{2011-08-22}
  s.authors = ["Sean Keith McAuley"]
  s.email = %q{sean@zarokeanpie.com}
  s.summary = %q{redis-structured-multi extends the redis gem's Redis#multi to allow data structures to be built from promises before data is fetched}
  s.homepage = %q{http://github.com/derefr/redis-structured-multi}
  s.description = %q{redis-structured-multi is an extension to the redis gem's Redis#multi that allows data structures to be built from the as-yet-unreturned values of the calls to Redis that occur within the #multi block.}
  s.files = [ "README.md", "LICENSE", "lib/redis/structured-multi.rb"]

  s.add_dependency('redis', '>= 2.2.2')
  s.add_dependency('fmap', '>= 0.0.1')
end
