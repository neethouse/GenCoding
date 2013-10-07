# coding: UTF-8

require "optparse"
require "pathname"
require "tempfile"

class GenCoding

  def initialize()
    @is_force = false
    @is_dry_run = false
  end
  attr_accessor :is_force, :is_dry_run, :path

  def generate(path)
    if path
      # fileの場合は対象ファイルを１つだけ処理
      # directoryの場合は再帰的に処理する
      # 別のFileメソッドに置き換える
      if File.ftype(path) == "file"
        header, source = pear_file(path)
        proc_file(header, source)
      elsif File.ftype(path) == "directory"
        each_file(path)
      else
        raise "Invalid ftype #{File.ftype(path)}"
      end
    end
  end

  def proc_file(header_file, source_file)

    # 両方のファイルが存在したら自動生成を開始する
    if File.exist?(header_file) && File.exist?(source_file)
      writer = SourceWriter.new(header_file)
      writer.rewrite(source_file, false)
    end

  end

  def each_file(dir)
    # .hをeachする
    Dir.glob(dir + "/**/*.h").each{|file|
      header, source = pear_file(file)
      proc_file(header, source)
    }
  end

  def pear_file(header_or_source)
    if header_or_source.end_with?(".m")
      # .m なので .hを探す
      return Pathname(header_or_source).sub_ext(".h").to_s, header_or_source
    elsif header_or_source.end_with?(".h")
      # .hなので .mを探す
      return header_or_source, Pathname(header_or_source).sub_ext(".m").to_s
    else
      raise "Illegal file type #{header_or_source}."
    end
  end

end

class ObjectiveCProperty

  attr_accessor :has_asterisk, :name, :type

  def initialize(line)
    # TODO: enumなのにNGC_EXPLICATE_TYPEが付いていない場合は警告を出す
    type_later = line.split(")").drop(1).join(")").split(";")[0].strip
    if type_later.include?("NGC_EXPLICATE_TYPE(")
      # 正規表現で抜き出したいヽ(•̀ω•́ )ゝ✧
      @type = type_later.split("NGC_EXPLICATE_TYPE(")[1].split(")")[0]
    else
      @type = type_later.split(" ")[0]
    end

    @name = type_later.split(" ")[1]

    @has_asterisk = @name.start_with?("*")
    if @has_asterisk
      # asteriskを除去する
      @name = @name[/[^\*]*$/]
    end
  end
end

class ObjectiveCInterface
  attr_reader :name, :properties
  def initialize(name)
    @name = name
    @properties = []
  end

  def addProperty(property)
    @properties.push(property)
  end

  def addPropertyFromLine(line)
    prop = ObjectiveCProperty.new(line)
    @properties.push(prop)
  end

  def getInitWithCoderMethods
    methods = @properties.map{ |prop|
      decodeLine(prop)
    }
  end

  def getEncodeWithCoderMethods
    methods = @properties.map{ |prop|
      encodeLine(prop)
    }
  end

  def encodeLine(property)
    if property.has_asterisk
      # NSObject系
      "NGCEncodeObject(#{property.name});"
    else
      # primitive系
      case property.type
      when "int"
        "NGCEncodeInt(#{property.name});"
      when "double"
        "NGCEncodeDouble(#{property.name});"
      when "float"
        "NGCEncodeFloat(#{property.name});"
      when "BOOL", "bool", "Boolean", "boolean_t"
        "NGCEncodeBool(#{property.name});"
      when "NSInteger"
        "NGCEncodeInteger(#{property.name});"
      when "int32_t"
        "NGCEncodeInt32(#{property.name});"
      when "int64_t"
        "NGCEncodeInt64(#{property.name});"
      end
    end
  end

  def decodeLine(property)
    if property.has_asterisk
      # NSObject系
      "NGCDecodeObject(#{property.name});"
    else
      # primitive系
      case property.type
      when "int"
        "NGCDecodeInt(#{property.name});"
      when "double"
        "NGCDecodeDouble(#{property.name});"
      when "float"
        "NGCDecodeFloat(#{property.name});"
      when "BOOL", "bool", "Boolean", "boolean_t"
        "NGCDecodeBool(#{property.name});"
      when "NSInteger"
        "NGCDecodeInteger(#{property.name});"
      when "int32_t"
        "NGCDecodeInt32(#{property.name});"
      when "int64_t"
        "NGCDecodeInt64(#{property.name});"
      end
    end
  end
end

class ObjectiveCHeaderFile


  attr_reader :interfaces

  def initialize(header_file)
    @interfaces = []

    clazz = nil #ObjectiveCInterface
    IO.foreach(header_file){|line|

      if !clazz && interface?(line)
        clazz = ObjectiveCInterface.new(interfaceName(line))
      elsif clazz && interface?(line)
        p "Logic error ?"
      end

      if clazz && end?(line)
        @interfaces.push(clazz)
        clazz = nil
      end

      if clazz && property?(line)
        clazz.addPropertyFromLine(line)
      end

    }
  end

  def end?(line)
    /^@end/ =~ line
  end

  def interface?(line)
    /@interface .+[ ]?:[ ]?.+<.*NGCCoding.*>/ =~ line
  end

  def property?(line)
      line.strip.start_with?("@property") && !line.include?("NGC_IGNORE_PROPERTY")
  end

  def interfaceName(line)
    line.scan(/@interface ([^ ]+)[ ]?:.*$/).flatten[0]
  end

end


#
#  Logic
#
#  Methodが存在するか?
#  ↓ Yes                        ↓ No
#  ↓                            METHOD_NOT_FOUND
#  ↓                            (自動生成する)
#  ↓
#  引数名(aDecoder)が変更されている?
#  ↓ Yes                              ↓ No
#  DETECT_ARGNAME_RENAME             ↓
#  (警告を出す -fなら強制上書き)      ↓
#                                     ↓
#                                     自動生成されたコードがある?
#                                     ↓ Yes                         ↓ No
#                                     ↓                            METHOD_ALREADY_CREATED
#                                     ↓                           (警告をだす. -fなら強制上書き)
#                                     ↓                           ブロックコメントそのものが編集されている場合もこれになる)
#                                     ↓
#                                     自動生成コードブロック内が編集されている?
#                                     ↓ Yes                               ↓ No
#                                     DETECT_AUTO_GEN_MODIFIED            AUTO_GEN_METHOD_FOUND
#                                     (警告を出す. -fなら強制上書き)      (自動生成ブロック内を更新)
#

module MethodStatus

  # Methodが存在しない
  METHOD_NOT_FOUND = 0

  # Methodは存在するが、自動生成されたものかは不明
  METHOD_ALREADY_CREATED = 1

  # 自動生成されたMethodが存在する
  AUTO_GEN_METHOD_FOUND = 2

  # 自動生成されたMethodが存在するが、編集された可能性がある
  DETECT_AUTO_GEN_MODIFIED = 3

  # Methodは存在するが引数名が aDecoder から変更されている
  DETECT_ARGNAME_RENAME = 4
end

module NGCCodingComments
  HEADER1 = "/*! [NGCCODING_BEGIN] This is auto generated code by NGCCoding. !*/"
  HEADER2 = "/*! [NGCCODING_BEGIN] Do not change this area.                  !*/"
  FOOTER  = "/*! [NGCCODING_END] End of auto generation.                     !*/"

  TRIMED_HEADER1 = HEADER1.strip.split(" ").join
  TRIMED_HEADER2 = HEADER2.strip.split(" ").join
  TRIMED_FOOTER = FOOTER.strip.split(" ").join
end

module ObjectiveCSyntax

  def matchImplementation?(line, name)
    line =~ /@implementation #{name}[ \n{]+/
  end

  def implementation?(line)
    /@implementation .+$/ =~ line
  end


  def implementationName(line)
    line.strip.scan(/@implementation ([^ \n{]+).*$/).flatten[0]
  end

  def end?(line)
    /^@end/ =~ line
  end

  def initWithCoder?(line)
    trimed = trim(line)
    trim(line).start_with?("-(id)initWithCoder:(NSCoder*)") ||
      trimed.start_with?("-(instancetype)initWithCoder:(NSCoder*)")
  end

  def encodeWithCoder?(line)
    trim(line).start_with?("-(void)encodeWithCoder:(NSCoder*)")
  end

  def firstBeginComment?(line)
    trim(line).start_with?(NGCCodingComments::TRIMED_HEADER1)
  end

  def secondBeginComment?(line)
    trim(line).start_with?(NGCCodingComments::TRIMED_HEADER2)
  end

  def endComment?(line)
    trim(line).start_with?(NGCCodingComments::TRIMED_FOOTER)
  end

  def ngcDecodeMacro?(line)
    trim(line).start_with?("NGCDecode")
  end

  def ngcEncodeMacro?(line)
    trim(line).start_with?("NGCEncode")
  end

  def aDecoder?(line)
    trim(line) =~ /\*\)aDecoder\{?$/
  end

  def aCoder?(line)
    trim(line) =~ /\*\)aCoder\{?$/
  end

  private
  def trim(line)
    line.strip.split(" ").join
  end

end

class MethodStatusQueue
  include ObjectiveCSyntax

  attr_accessor :name

  def initialize(name)
    @name = name
    @state = MethodStatus::METHOD_NOT_FOUND
    @next = method(:findMethod)
    @pre_hook = nil
    @brace_count = 0
  end

  def countBrace(line)
    if @brace_count > 0
      @brace_count = @brace_count.succ if line.include?("{")
      @brace_count = @brace_count.pred if line.include?("}")
      if @brace_count == 0
        @next = method(:empty)
      end
    else
      @brace_count = @brace_count.succ if line.include?("{")
      @brace_count = @brace_count.pred if line.include?("}")
    end
  end

  def scan(line)
    @pre_hook.call(line) if @pre_hook
    @next.call(line)
  end

  def take
    @state
  end

  private
  def findMethod(line)
    raise "Do not call."
  end

  def findFirstBeginComment(line)
    if firstBeginComment?(line)
      @next = method(:findSecondBeginComment)
    end
  end

  def findSecondBeginComment(line)
    if secondBeginComment?(line)
      @next = method(:findNGCMacro)
    end
  end

  def findNGCMacro(line)
    raise "Do not call."
  end

  def empty(line)
  end

end

class InitWithCoderMethodStatusQueue < MethodStatusQueue

  def findMethod(line)
    if initWithCoder?(line)
      @state = MethodStatus::METHOD_ALREADY_CREATED
      @next = method(:findFirstBeginComment)
      countBrace(line)
      @pre_hook = method(:countBrace)

      if !aDecoder?(line)
        @state = MethodStatus::DETECT_ARGNAME_RENAME
        @next = method(:empty)
      end
    end
  end

  def findNGCMacro(line)
    if endComment?(line)
      @state = MethodStatus::AUTO_GEN_METHOD_FOUND
      @next = method(:empty)
    elsif !ngcDecodeMacro?(line)
      @state = MethodStatus::DETECT_AUTO_GEN_MODIFIED
      @next = method(:empty)
    end
  end
end

class EncodeWithCoderMethodStatusQueue < MethodStatusQueue

  def findMethod(line)
    if encodeWithCoder?(line)
      @state = MethodStatus::METHOD_ALREADY_CREATED
      @next = method(:findFirstBeginComment)
      countBrace(line)
      @pre_hook = method(:countBrace)

      if !aCoder?(line)
        @state = MethodStatus::DETECT_ARGNAME_RENAME
        @next = method(:empty)
      end
    end
  end

  def findNGCMacro(line)
    if endComment?(line)
      @state = MethodStatus::AUTO_GEN_METHOD_FOUND
      @next = method(:empty)
    elsif !ngcEncodeMacro?(line)
      @state = MethodStatus::DETECT_AUTO_GEN_MODIFIED
      @next = method(:empty)
    end
  end
end

class ObjectiveCSourceFile
  include ObjectiveCSyntax


  attr_reader :statuses

  def initialize(source_file)
    @statuses = []
    stacks = []

    # decode
    IO.foreach(source_file){|line|
      if stacks.empty? && implementation?(line)
        name = implementationName(line)
        stacks.push(InitWithCoderMethodStatusQueue.new(name))
        stacks.push(EncodeWithCoderMethodStatusQueue.new(name))
      end

      if !stacks.empty?

        stacks.each{|s| s.scan(line)}

        if end?(line)
          status = ObjectiveCImplStatus.new(stacks[0].name)
          status.init_with_coder = stacks[0].take
          status.encode_with_coder = stacks[1].take
          @statuses.push(status)
          stacks.clear
        end
      end
    }

  end

end

class ObjectiveCImplStatus

  attr_accessor :name, :init_with_coder, :encode_with_coder

  def initialize(name)
    @name = name
    @init_with_coder = nil
    @encode_with_coder = nil
  end
end


class SourceWriter
  include ObjectiveCSyntax

  def initialize(header_file)
    # headerを解析する
    @header = ObjectiveCHeaderFile.new(header_file)
  end

  def rewrite(source_file, force)


    objective_source = ObjectiveCSourceFile.new(source_file)


    # TODO:１つづつ愚直にやっていかないと駄目かもしれない...
    @header.interfaces.each{ |interface|

      status = objective_source.statuses.find{|s| s.name == interface.name}
      if status

        if status.init_with_coder == MethodStatus::METHOD_NOT_FOUND ||
          status.encode_with_coder == MethodStatus::METHOD_NOT_FOUND

          writeEmptyMethod(source_file, status)
          writeNSCodingMethods(source_file, interface)
        end

        if status.init_with_coder == MethodStatus::AUTO_GEN_METHOD_FOUND ||
          status.encode_with_coder == MethodStatus::AUTO_GEN_METHOD_FOUND

          removeGeneratedCode(source_file, status)
          writeNSCodingMethods(source_file, interface)
        end

        if force
          # メソッドを削除する
          #removeNSCodingMethod(source_file)

          #書き換え
        else
          putWarnMessage(status)
        end
      end
    }

    return

  end

  def putWarnMessage(status)
    # TODO:いい感じにしたい
    # initWithCoder
    case status.init_with_coder
    when MethodStatus::METHOD_ALREADY_CREATED
      p status.name
      p "initWithCoder method is already created. -f option : force overwrite."
    when MethodStatus::DETECT_AUTO_GEN_MODIFIED
      p status.name
      p "initWithCoder method has been changed. -f option : force overwrite."
    when MethodStatus::DETECT_ARGNAME_RENAME
      p status.name
      p "Name of aDecoder argument has changed. -f option : force overwrite."
    end

    # encodeWithCoder
    case status.encode_with_coder
    when MethodStatus::METHOD_ALREADY_CREATED
      p status.name
      p "encodeWithCoder method is already created. -f option : force overwrite."
    when MethodStatus::DETECT_AUTO_GEN_MODIFIED
      p status.name
      p "encodeWithCoder method has been changed. -f option : force overwrite."
    when MethodStatus::DETECT_ARGNAME_RENAME
      p status.name
      p "Name of aDecoder argument has changed. -f option : force overwrite."
    end
  end


  def writeNSCodingMethods(source_file, interface)

    tmp_file = Tempfile.open("gencode_decode_tmp_file"){|fp|
      prev_line = ""
      in_imple = false
      on = nil
      IO.foreach(source_file) {|line|
        trimed_line = line.strip.split(" ").join

        if in_imple
          if trimed_line.include?(")initWithCoder:(NSCoder*)")
            on = "initWithCoder"
          end
          if trimed_line.include?(")encodeWithCoder:(NSCoder*)")
            on = "encodeWithCoder"
          end

          # 判断する
          if trimed_line.start_with?(NGCCodingComments::TRIMED_FOOTER) &&
            prev_line.strip.split(" ").join.start_with?(NGCCodingComments::TRIMED_HEADER2)

            space_count = countSpace(line)
            if on == "initWithCoder"
              methods = interface.getInitWithCoderMethods
              methods.each{|m| fp.puts((" " * space_count) + m)}
            elsif on == "encodeWithCoder"
              methods = interface.getEncodeWithCoderMethods
              methods.each{|m| fp.puts((" " * space_count) + m)}
            end
          end

          if end?(line)
            in_imple = false
          end
        else
          in_imple = true if matchImplementation?(line, interface.name)
        end

       fp.puts line
       prev_line = line
      }
      fp.path
    }
    replaceFile(source_file, tmp_file)

  end

  def countSpace(line)
    line.scan(/(^ *)/).flatten[0].count(" ")
  end

  def writeEmptyMethod(source_file, status)

    tmp_file = Tempfile.open("gencode_empty_tmp_file"){|fp|
      in_imple = false

      # 新規作成
      IO.foreach(source_file) {|line|
        if in_imple
          if end?(line)
            in_imple = false
            # initWithCoder
            if status.init_with_coder == MethodStatus::METHOD_NOT_FOUND
              fp.puts getTemplate("decode")
            end

            if status.encode_with_coder == MethodStatus::METHOD_NOT_FOUND
              fp.puts getTemplate("encode")
            end

            fp.puts "@end"
          else
            fp.puts line
          end
        else
          in_imple = true if matchImplementation?(line, status.name)
          fp.puts line
        end

      }
      fp.path
    }
    replaceFile(source_file, tmp_file)
  end



  def removeNSCodingMethod(source_file, status)
    tmp_file = Tempfile.open("gencode_remove_method_tmp_file"){|fp|
      IO.foreach(source_file){|line|
        trimed_line = line.strip.split(" ").join

        in_method = false

        if trimed_line.include?(")initWithCoder:(NSCoder*)") &&
          (status.init_with_coder == MethodStatus::DETECT_AUTO_GEN_MODIFIED)

          in_method = true
        end
        if trimed_line.include?(")encodeWithCoder:(NSCoder*)") &&
          (status.init_with_coder == MethodStatus::DETECT_AUTO_GEN_MODIFIED)
          in_method = true
        end

        # 判断する
        if trimed_line.start_with?(NGCCodingComments::TRIMED_FOOTER)
          if on == "initWithCoder"
            fp.puts @builder.buildInitWithCoder(8)
          elsif on == "encodeWithCoder"
            fp.puts @builder.buildEncodeWithCoder(4)
          end
        end

        fp.puts line
      }
      fp.path

    }

  end

  def removeGeneratedCode(source_file, status)
    tmp_file = Tempfile.open("gencode_remove_tmp_file"){|fp|

      in_imple = false
      in_method = false
      in_block = false
      IO.foreach(source_file){|line|
        trimed_line = line.strip.split(" ").join


        if in_imple
          if end?(line)
            in_imple = false
          end
        else
          in_imple = true if matchImplementation?(line, status.name)
        end

        if !in_method && in_imple
          if status.init_with_coder == MethodStatus::AUTO_GEN_METHOD_FOUND
            in_method = true if initWithCoder?(line)
          end

          if status.encode_with_coder == MethodStatus::AUTO_GEN_METHOD_FOUND
            in_method = true if encodeWithCoder?(line)
          end
        end


        if in_imple && in_method
          if trimed_line.start_with?(NGCCodingComments::TRIMED_FOOTER)
            in_method = false
            in_block = false
          end

          if !in_block
            fp.puts line
          end

          if trimed_line.start_with?(NGCCodingComments::TRIMED_HEADER2)
            in_block = true
          end
        else
          fp.puts line
        end

        #p line
        #p "in_imple : " + in_imple.to_s + ", in_method : " + in_method.to_s + ", in_block : " + in_block.to_s

      }
      fp.path
    }

    replaceFile(source_file, tmp_file)
  end

  # src_fileを削除してdest_fileに置き換える
  def replaceFile(src_file, dest_file)
    if File.exist?(src_file) && File.exist?(dest_file)
      File.delete(src_file)
      File.rename(dest_file, src_file)
    end
  end

  def getTemplate(kind)
    case kind
    when "decode"
      <<EOS
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        /*! [NGCCODING_BEGIN] This is auto generated code by NGCCoding. !*/
        /*! [NGCCODING_BEGIN] Do not change this area.                  !*/
        /*! [NGCCODING_END] End of auto generation.                     !*/
    }
    return self;
}

EOS
    when "encode"
      <<EOS
- (void)encodeWithCoder:(NSCoder *)aCoder {
    /*! [NGCCODING_BEGIN] This is auto generated code by NGCCoding. !*/
    /*! [NGCCODING_BEGIN] Do not change this area.                  !*/
    /*! [NGCCODING_END] End of auto generation.                     !*/
}

EOS
    end
  end


end

gencoding = GenCoding.new

opt = OptionParser.new
opt.version = "0.0.1"

opt.on_tail("-h", "--help") do
  p opt
  p "See more information https://github.com/neethouse/GenCoding"
  exit
end

# force overwrite
opt.on("-f", "--force", "force overwrite") {|v| gencoding.is_force = v}

# dry run
opt.on("-n", "--dry-run", "dry run") {|v| gencoding.is_dry_run = v}

opt.parse(ARGV)

# 最後の引数はワーキングディレクトリ
# 存在しなければ終了
path = ARGV.last
if File.exist?(path)
  gencoding.generate(path)
else
  p path + " not found."
  p opt
  exit
end

