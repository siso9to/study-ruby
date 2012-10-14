# encoding: utf-8
class Lawyer
  def method_missing(method, *args) 
    puts "#{method}(#{args.join(', ')})を呼び出した"
    puts "(ブロックを渡した)" if block_given?
  end
end

bob = Lawyer.new

bob.talk_simple('a','b') do
  # hoge
end

bob.talk_simple('a')
