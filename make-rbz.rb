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
# => --o <name>
#   sets the output file name for the RBZ file. Default is the repo name
#   eg ruby make-rbz --o myScript.rbz
# => --p <path>
#   sets the output directory for the RBZ file. Default is the current working
#   directory
# => --d [prefix]
#   sets the output file name for the RBZ file to be a combination of the given
#   prefix and the value from `git describe`. If a prefix is not given, it is
#   assumed to be the repo name
# => --s <path>
#   sets the source path for files to be added to the RBZ file. This path will
#   treated as if it were the "plugins" folder - it will not be included in the
#   RBZ but all of its contents will
# => -v
#   activate verbose mode. All added files will be printed to STDOUT
# => -f
#   force overwrite. This will overwrite the output file is it already exists
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
    :output_path => '.',
    :output_file => nil,
    :source => 'src',
    :verbose => false,
    :force => false,
    :compress => false
}
FILE_NAME_FORBIDDEN = /[\<\>\:\"\/\\\|\?\*\/]/
REPO_NAME = File.basename(File.dirname(__FILE__))

OptionParser.new {|opts|
    opts.banner = "Usage : ruby #{File.basename(__FILE__)} [OPTIONS]"
    opts.on("--p <path>") {|v|
        OPTIONS[:output_path] = v
    }
    opts.on("--o <name>") {|file_name|
        unless OPTIONS[:output_name].nil?
            abort("--o cannot be used with -d")
        end
        OPTIONS[:output_name] = file_name.gsub(FILE_NAME_FORBIDDEN, '-')
    }
    opts.on("--s <path>") {|path|
        OPTIONS[:source] = path
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
    opts.on("--d [prefix]") {|prefix|
        unless OPTIONS[:output_name].nil?
            abort("--o cannot be used with -d")
        end
        begin
            desc = `git describe`.strip()
        rescue => e
            abort("Error reading repo description")
        end
        desc.gsub!(FILE_NAME_FORBIDDEN, '-')
        prefix = (prefix || REPO_NAME).gsub(FILE_NAME_FORBIDDEN, '-')
        OPTIONS[:output_file] = prefix + '_' + desc
    }
}.parse!

OPTIONS[:output_file] ||= REPO_NAME
OPTIONS[:output] = File.join(OPTIONS[:output_path], OPTIONS[:output_file])
if File.extname(OPTIONS[:output]).downcase() != '.rbz'
    OPTIONS[:output] += '.rbz'
end


if File.exists?(OPTIONS[:output])
    if OPTIONS[:force]
        File.delete(OPTIONS[:output])
    else
        raise abort([
            "target output file already exists.",
            "Use -f to overwrite #{OPTIONS[:output]}"
        ].join(''))
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
