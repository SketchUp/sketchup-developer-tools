###############################################################################
# make-rbz.rb tool - makes RBZ files
###############################################################################
# (c) 2012 Daniel Bowring, released under GPL - feel free to modify,
# distribute, ...
# Requirements:
# => Ruby 1.8.* (If you have ruby installed for SketchUp - that's perfect!)
# => rubygems
# => rubyzip2
# Usage:
# ruby make-rbz.rb
# Options:
# => --o [path]
#   sets the output for the RBZ file. should include the .rbz extension
#   eg ruby make-rbz --o myScript.rbz
# => -- s [path]
#   sets the source path for files to be added to the RBZ file. This path will
#   treated as if it were the "plugins" folder - it will not be included in the
#   RBZ but all of its contents will
# => -v
#   activate verbose mode. All added files will be printed to STDOUT
# => -f
#   force overwrite. This will remove the output path is it already exists
# => -c
#   activate zip compression
###############################################################################

begin
    require 'rubygems'
rescue => e
    puts "Error - rubygems required but failed to load"
    raise e
end

begin
    require 'zip/zip'
rescue => e
    puts "Error - zip/zip required but failed to load"
    raise e
end

require 'optparse'
require 'zlib'

LEVEL = Zlib::BEST_COMPRESSION
OPTIONS = {
    :output => 'sketchup-developer-tools.rbz',
    :source => 'src',
    :verbose => false,
    :force => false,
    :compress => false
}

OptionParser.new {|opts|
    opts.banner = "Usage : ruby #{File.basename(__FILE__)} [OPTIONS]"
    opts.on("--o [path]") {|v|
        OPTIONS[:output] = v
    }
    opts.on("--s [path]") {|v|
        OPTIONS[:source] = v
    }
    opts.on("-v") {|v|
        OPTIONS[:verbose] = v
    }
    opts.on("-f") {|v|
        OPTIONS[:force] = v
    }
    opts.on("-c") {|v|
        OPTIONS[:compress] = v
    }
}.parse!


if File.exists?(OPTIONS[:output])
    if OPTIONS[:force]
        File.delete(OPTIONS[:output])
    else
        raise IOError.new("target output file already exists. use -f to overwrite")
    end
end

def zipped_path(file)
    return file.sub(OPTIONS[:source] + '/', '')
end

def create_uncompressed()
    Zip::ZipFile.open(OPTIONS[:output], Zip::ZipFile::CREATE) {|zip|
    Dir[File.join(OPTIONS[:source], '**', '**')].each{|file|
            puts file if OPTIONS[:verbose]
            zip.add(zipped_path(file), file)
        }
    }
end

def create_compressed()
    Zip::ZipOutputStream.open(OPTIONS[:output]) {|zip|
        Dir[File.join(OPTIONS[:source], '**', '**')].each{|file|
            puts file if OPTIONS[:verbose]
            entry = Zip::ZipEntry.new("", zipped_path(file))
            entry.gather_fileinfo_from_srcpath(file)
            zip.put_next_entry(entry, LEVEL)
            entry.get_input_stream { |is| IOExtras.copy_stream(zip, is) }
        }
    }
end

OPTIONS[:compress] ? create_compressed() : create_uncompressed()

puts "Success - wrote to #{OPTIONS[:output]}"
