if ARGV.empty?
  puts "  Missing executable file argument"
  puts "  Usage (in a Dockerfile):"
  puts "  RUN ruby ./path/to/list_deps.rb ./bin/executable"
  exit 1
end

executable = File.expand_path(ARGV[0])

unless File.exist?(executable)
  puts "  Unable to find #{executable}"
  exit 1
end

puts "  Extracting libraries for #{executable} ..."

deps = []
output = %x{ldd #{executable}}
output.scan(/(\/.*)\s\(/) do |match|
  library = match[0]
  deps << library

  real_lib = File.realpath(library)
  deps << real_lib if real_lib != library
end

deps.uniq! # Remove duplicates

puts "  Generating Dockerfile"
puts
puts "=" * 30
puts "FROM scratch"
deps.each do |dep|
  puts "COPY --from=0 #{dep} #{dep}"
end
puts "COPY --from=0 #{executable} /#{File.basename(executable)}"
puts "ENTRYPOINT [\"/#{File.basename(executable)}\"]"
puts "=" * 30