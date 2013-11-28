$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

require 'sixamo'

if $0 == __FILE__
  opt = {}
  while o = ARGV[0]
    case o
    when '-i'; opt[:i] = true;
    when '-m'; opt[:m] = true;
    when '-im'; opt[:i] = opt[:m] = true;
    when '--init'; opt[:init] = true;
    else break;
    end
    ARGV.shift
  end
  if opt[:init]
    dic = Sixamo.init_dictionary(ARGV[0])
    dic.save_dictionary
  elsif opt[:i]
    require 'readline'
    sixamo = Sixamo.new(ARGV[0])
    puts "簡易対話モード [exit, quit, 空行で終了]"
    while (str = Readline.readline("> ", true))
      break if /^(exit|quit)?$/.match(str)
      if opt[:m]
        sixamo.memorize([str])
        puts sixamo.talk
      else
        puts sixamo.talk(str)
      end
    end
  else
    puts Sixamo.new(ARGV[0] || "data").talk(ARGV[1])
  end
end
