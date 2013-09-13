#!/usr/bin/env ruby

require 'pp'

$stack = []
$cstack = []
$dict = {}

# evaluate code immediately
$eval_handler = proc {|w|
    r = $dict[w.to_sym]
    if(r)
        r.call()
    else
        $stack.push(eval(w))
    end
}

# compile a block
$comp_handler = proc {|w|
    if(w == ";")
        routine = $stack.pop
        $dict[routine.shift.to_sym] = proc {run(routine)}
        $cstack.pop()
    elsif(w == ";]")
        routine = $stack.pop
        $stack.push(proc {run(routine)})
        $cstack.pop()
    else
        $stack[-1].push(w)
    end
}

# handle range comments, started with '(' and ended with ')'. Comments may be nested.
$range_comment_handler = proc {|w|
    if(w == ")")
        $cstack.pop()
    elsif(w == "(")
        $cstack.push($range_comment_handler)
    end
}

$cstack.push($eval_handler)

def run(s)
    s.each {|w|
        if(w == "\\")
            break;
        end
        $cstack[-1].call(w)
    }
end

$dict[:swap] = proc {r = $stack.pop; l = $stack.pop; $stack.push(r); $stack.push(l)}
$dict[:swap2] = proc {d = $stack.pop; c = $stack.pop; b = $stack.pop; a = $stack.pop; $stack.push(c); $stack.push(d); $stack.push(a); $stack.push(b)}
$dict[:rot] = proc {c = $stack.pop; b = $stack.pop; a = $stack.pop; $stack.push(b); $stack.push(c); $stack.push(a)}
$dict[:rrot] = proc {c = $stack.pop; b = $stack.pop; a = $stack.pop; $stack.push(c); $stack.push(a); $stack.push(b)}
$dict[:pop] = proc {$stack.pop}
$dict[:pop2] = proc {$stack.pop; $stack.pop}
$dict[:dup] = proc {$stack.push($stack[-1])}
$dict[:dup2] = proc {$stack.push($stack[-2]); $stack.push($stack[-2])}
$dict[:over] = proc {$stack.push($stack[-2])}

$dict[:+] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l + r)}
$dict[:-] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l - r)}
$dict[:*] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l*r)}
$dict[:**] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l**r)}
$dict[:/] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l/r)}

$dict[:<] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l < r)}
$dict[:>] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l > r)}
$dict["<=".to_sym] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l <= r)}
$dict[">=".to_sym] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l >= r)}
$dict[:eq] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l == r)}
$dict[:neq] = proc {r = $stack.pop; l = $stack.pop; $stack.push(l != r)}
$dict[:not] = proc {v = $stack.pop; $stack.push(!v)}

$dict["[:".to_sym] = proc {$stack.push([]); $cstack.push($comp_handler)}
$dict[":".to_sym] = proc {$stack.push([]); $cstack.push($comp_handler)}
$dict["(".to_sym] = proc {$cstack.push($range_comment_handler)}

$dict[:call] = proc {$stack.pop.call()}
$dict[:ifelse] = proc {ep = $stack.pop; ip = $stack.pop; c = $stack.pop; ((c)? ip : ep).call()}
$dict[:cond] = proc {p = $stack.pop; c = $stack.pop; if(c) then p.call() end}

$dict[:while] = proc {
    p = $stack.pop; c = $stack.pop;
    c.call(); while($stack.pop) do p.call(); c.call(); end
}

$dict[:cr] = proc {print "\n"}
$dict[:emit] = proc {print $stack.pop}
$dict[".s".to_sym] = proc {pp $stack}

File.open(ARGV[0]).each_line {|line| run(line.split(' '))}
