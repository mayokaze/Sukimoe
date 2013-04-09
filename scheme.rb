require "rsec"

class Scheme
  include Rsec::Helpers
  
  Env  = Hash.new
  Closure =  Struct.new(:f,:p,:ctx)
  
  ValNode = Struct.new :val
  class ValNode
    def eval env = Env
      val  
    end  
  end  
  
  class ListNode < Array  
    def eval env = Env   
      head, *tail = self  
      case head  
       when "+"
         tail[0].eval(env) + tail[1].eval(env)
       when "-"
         tail[0].eval(env)   - tail[1].eval(env) 
       when "*"
         tail[0].eval(env)   * tail[1].eval(env)  
       when "/"
         tail[0].eval(env)   / tail[1].eval(env) 
      when "define"
        if tail[1].is_a? ValNode
          env[tail[0].eval(env) ] = tail[1]
        else  
         env[tail[0].eval(env) ] = tail[1].eval(env)
       end 
      when "lambda"
        Closure.new(tail[1],tail[0].eval(env),env)
      when "print"
        puts tail[0].eval(env)
      when  String
       env[head] ? env[head].eval(env) : head
        
      when Array
        if head[0].is_a? String and val = env[head[0]] and val.is_a?(Closure)
          env =  env.merge(val.ctx)
          env[val.p]  = tail[0]
          val.f.eval env
        else
         self.map{|n|  n.eval }.last   
       end
      end  
    end  
  end  
  
   def initialize
    integer = /0|[1-9]\d*/.r {|n| ValNode[n.to_i]}
    op = one_of_('+-*/')
    id = /[^\s\(\)\[\]]+/.r {|n| ListNode[*n] }
    value    = integer | lazy{list}|id
    calc    = seq_('(',op, value, value,')'){|n| ListNode[n[1],n[2],n[3]]} 
    lambda =  seq_('(',word('lambda'), id,lazy{list},')'){|n| ListNode[n[1],n[2],n[3]] }
    invoke =  seq_('(',id,value,')'){|n| ListNode[n[1],n[2]] }
    display = seq_('(',word('print'),lazy{list},')'){|n| ListNode[n[1],n[2]] }
    define =  seq_('(',word('define'),id,lazy{list},')') {|n| ListNode[n[1],n[2],n[3]] }
    list = calc|display|invoke|lambda|define|integer|id
    program = /\s*/.r.join(list).odd {|n| ListNode[*n] }
    @parser = program.eof
 end
  
  def run source
    res =  @parser.parse! source
    # res
   res.eval 
  end
end

ARGV[0] ? Scheme.new.run(File.read ARGV[0]) : puts('need a scheme file name')  

