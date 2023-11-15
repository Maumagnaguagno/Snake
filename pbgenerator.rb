#!/usr/bin/env ruby
#-----------------------------------------------
# Snake problem generator
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Expects text based files describing a grid-based scenario with:
# - Space as clear location
# - @ as snake head location
# - $ as snake body location
# - * as mouse location
# - # as wall location
# Currently limited to a single snake, snake body locations should be adjacent only to previous and next locations
#-----------------------------------------------

PDDL_HDDL_TEMPLATE = "(define (problem <PROBLEM_NAME>)
  (:domain snake)\n
  (:objects
    viper - snake<LOCATIONS> - location
  )\n
  (:init
    (head viper <HEAD>)
    <CONNECTED>
    (tail viper <TAIL>)\n
    <MOUSE-AT>\n
    <OCCUPIED>\n<HORIZONTAL>\n<VERTICAL>
  )\n
  <GOAL_TASK>
)"

JSHOP_TEMPLATE = "(defproblem <PROBLEM_NAME> snake
  (;init
    (snake viper)<LOCATIONS>
    (head viper <HEAD>)
    <CONNECTED>
    (tail viper <TAIL>)\n
    <MOUSE-AT>\n
    <OCCUPIED>\n<HORIZONTAL>\n<VERTICAL>
  )
  (;task
    (hunt)
  )
)"

def generate_problem(type, filename, template)
  # Parsing
  x = y = 0
  width = nil
  snake = []
  body = []
  mouses = []
  walls = []
  File.read(filename).each_char {|c|
    case c
    when '@'
      abort("Multiple snakes in #{filename}") unless snake.empty?
      snake << [x, y]
    when '$' then body << [x, y]
    when '*' then mouses << [x, y]
    when '#' then walls << [x, y]
    when "\n"
      if width
        abort("Width does match previous line in #{filename}") if width != x
      else width = x
      end
      x = -1
      y += 1
    end
    x += 1
  }
  abort("Missing snake head @ in #{filename}") if snake.empty?

  # Connect body locations to snake
  until body.empty?
    unless body.reject! {|b| snake << b if snake[-1][0] == b[0] && (snake[-1][1] - b[1]).abs == 1 or (snake[-1][0] - b[0]).abs == 1 && snake[-1][1] == b[1]}
      abort("Disconnected snake body part in #{filename}")
    end
  end

  locations = ''
  horizontal = ''
  vertical = ''
  (y + 1).times {|j|
    locations << "\n   "
    horizontal << "\n   "
    vertical << "\n   " if j != y
    width.times {|i|
      locations << center = " px#{i}y#{j}"
      horizontal << " (adjacent#{center} #{right = "px#{i.succ}y#{j}"}) (adjacent #{right}#{center})" if i != width.pred
      vertical << " (adjacent#{center} #{bottom = "px#{i}y#{j.succ}"}) (adjacent #{bottom}#{center})" if j != y
    }
  }

  # Compile
  template.sub!('<PROBLEM_NAME>', File.basename(filename, '.*'))
  template.sub!('<HEAD>', "px#{snake[0][0]}y#{snake[0][1]}")
  template.sub!('<CONNECTED>', snake.each_cons(2).map {|(x1,y1),(x2,y2)| "(connected viper px#{x1}y#{y1} px#{x2}y#{y2})"}.join("\n    "))
  template.sub!('<TAIL>', "px#{snake[-1][0]}y#{snake[-1][1]}")
  template.sub!('<MOUSE-AT>', mouses.map {|x,y| "(mouse-at px#{x}y#{y})"}.join("\n    "))
  template.sub!('<OCCUPIED>', (snake + mouses + walls).sort_by! {|x,y| x + y * width}.map! {|x,y| "(occupied px#{x}y#{y})"}.join("\n    "))
  template.sub!('<HORIZONTAL>', horizontal)
  template.sub!('<VERTICAL>', vertical)
  case type
  when 'pddl'
    template.sub!('<LOCATIONS>', locations)
    template.sub!('<GOAL_TASK>', "(:goal (and#{mouses.map {|x,y| "\n    (not (mouse-at px#{x}y#{y}))"}.join}\n  ))")
  when 'hddl'
    template.sub!('<LOCATIONS>', locations)
    template.sub!('<GOAL_TASK>', '(:htn :subtasks (hunt))')
  else
    template.sub!('<LOCATIONS>', locations.gsub!(/(\S+)/, '(location \1)'))
  end
  File.binwrite("#{filename}.#{type}", template)
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  case type = ARGV.shift
  when 'pddl', 'hddl' then template = PDDL_HDDL_TEMPLATE
  when 'jshop' then template = JSHOP_TEMPLATE
  else abort('ruby pbgenerator.rb type [pb1.snake ... pbN.snake]')
  end
  (ARGV.empty? ? Dir.glob('*.snake') : ARGV).each {|filename| generate_problem(type, filename, template.dup)}
end