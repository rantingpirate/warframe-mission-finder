#!/bin/ruby

$verbose = 0
$shortargs = 'nNvqdDiImcbMC' #h'
$longargs = ["verbose","quiet","debug","no-debug","invert","no-invert",
"mean","no-mean","chance","no-chance","both","name","iname"].map{|s| '-' + s} #,"help"]
$args = []
$values = []
$debug = false
$invert = false
$normal = true
$chance = true
$mean = false
$name = nil
$iname = nil

def badarg(arg)
	$stderr.puts "I don't understand the argument '-#{arg}'."
	# write_help true
	exit(1)
end #def badarg(arg)


while 0 < ARGV.length do
	# puts "ARGV:#{ARGV}, $arg#{$args}, $val#{$values}" #DEBUG
	case ARGV[0]
	when /^--$/
		ARGV.shift
		$values.concat(ARGV)
		break
	when /^(-|\+)/
		arg = ARGV.shift
		if arg.start_with? '--'
			if $longargs.include? arg.delete_prefix('-')
				$args.push(arg)
			else badarg(arg)
			end
		else
			args = arg.split ''
			prefix = args.shift
			args.each{|a|
				if $shortargs.include? ('-' == prefix ? a : "+#{a}")
					$args.push a.prepend(prefix)
				else badarg(a.prepend(prefix))
				end
			}
		end #if arg starts with '--'
	else
		$values.push(ARGV.shift)
	end #case ARGV[0]
end #while 0 < ARGV.length
# puts "ARGV:#{ARGV}, $arg#{$args}, $val#{$values}" #DEBUG

$args.each do |arg|
	case arg
	when /--iname/
		$iname = false
	when /-v|--verbose/
		$verbose += 1
	when /-q|--quiet/
		$verbose -= 1
	when /-d|--debug/
		$debug = true
	when /-D|--no-debug/
		$debug = false
	when /-i|--invert/
		$invert = true
		$normal = false
	when /-I|--no-invert/
		$invert = false
		$normal = true
	when /-m|--mean/
		$mean = true
	when /-M|--no-mean/
		$mean = false
	when /-c|--chances/
		$chance = true
	when /-C|--no-chances/
		$chance = false
	when /-b|--both/
		$invert = true
		$normal = true
	when /-n|--name/
		$name = false
	end #case arg
	args.shift
end #args.each

if false === $name
	$name = "\"#{$values.shift}\": "
else
	$name = ""
end
if false === $iname
	$iname = "\"#{$values.shift}\": "
else
	$iname = ""
end


def addChances(chances)
	n = 1
	puts "#{chances}" if $debug or 3 <= $verbose
	chances.each{|ch, inv| n *= inv ? 1 - ch : ch}
	return n
end #def addChances

def runPerms(perms, arry, set = nil, i = 0)
	set = [] if not set
	puts "prm:#{perms}, set:#{set}, arry:#{arry}, i:#{i}" if $debug 
	if arry.length <= i
		if $debug or 1 <= $verbose
			print_to = $debug ? STDERR : STDOUT
			print_to.print "#{arry.length} <= #{i}; (#{perms}) " if $debug
			print_to.print "perms[#{set.select{|c| !c[1]}.length}] += #{addChances set}"
			print_to.print " (#{set})" if $debug or 2 <= $verbose
			print_to.print "\n"
		end
		perms[set.select{|c| !c[1]}.length] += addChances(set)
	else
		puts "prm:#{perms}, set:#{set}" if $debug or 3 <= $verbose
		runPerms(perms, arry, set + [[arry[i], true]], i+1)
		puts "prm:#{perms}, set:#{set}" if $debug
		runPerms(perms, arry, set + [[arry[i], false]], i+1)
		puts "prm:#{perms}, set:#{set}" if $debug
	end
end #def runPerms
def chancePermutations(arry)
	perms = [0] * (arry.length + 1)
	# (0..arry.length).each{|i| perms[i] = 0}
	runPerms(perms, arry)
	while 0 < perms.length and 0 == perms.last
		perms.pop
	end
	return perms
end #def chancePermutations
def chMean(chances)
	mean = 0
	chances.each.with_index{|ch,i| mean += ch * i}
	return mean
end

def sanefloat(num, precision: 9, places: false, max_zeroes: 3)
	return ("%.#{precision}f" % num).to_f
	# lim = max_zeroes + 1
	# pre = precision - lim
	# nums = num.to_s.gsub(/
	# 	(?<=#{
	# 			places ? "" : "[1-9]\d{#{pre-1}}|"
	# 	 	}[1-9][0-9.]{#{pre}}
	# 	) 0{#{lim},} ([0-4]\d+)? $
	# /x,"")
	# usenums = nums.gsub /^[0.]*/, ''
	# prec = precision + 2
	# prec += 1 if usenums.include? '.'
	# nums.concat("0" * (prec - usenums.length)) if usenums.length < prec
	# nums.concat("0") if nums.end_with? "."
end #def sanefloat
def putarr(arr, prefix = "", inverted: false, **keyargs)
	parr = arr.map{|ch| sanefloat(ch, **keyargs)}
	puts "#{prefix}#{inverted ? $iname : $name}#{parr} (#{sanefloat parr.sum})"
end #def putarr


aabc = $values.map{|v| (v.end_with? "%" or 1.0 < v.to_f) ? v.to_f / 100 : v.to_f}
perms = chancePermutations(aabc)
iperms = chancePermutations(aabc.map{|ch| 1-ch}) if $invert
putarr(perms, ($invert ? "Chances:  " : $mean ? "Chances: " : "")) if $chance and $normal
putarr(iperms, "Inverted: ", inverted: true) if $chance and $invert
puts "#{$name}#{sanefloat chMean perms}".prepend ($invert ? "Normal mean:   " : $chance ? "Mean: " : "") if $mean and $normal
puts "Inverted mean: #{$iname}#{sanefloat chMean iperms}" if $mean and $invert

