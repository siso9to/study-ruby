# encoding: utf-8

#=2.2 動的メソッド
#==2.2.1 メソッドを動的に呼び出す
#===ドット記法の場合
#  class MyClass
#    def my_method(my_arg)
#      my_arg * 2
#    end
#  end
#
#  obj = MyClass.new
#  obj.my_method(3)  # => 6
#
#===Object.send()を使って呼び出す方法
#  obj.send(:my_method, 3) #=> 6
#
#send()の場合、呼び出したいメソッド名は通常の引数になるので、
#コードの実行時に呼び出すメソッドを直前に決められる。
#この技術を動的ディスパッチと呼ぶ。
#
#===Campingの例
#省略
#
#===Test::Unitの例
#  method_names = public_instance_methods(true)
#  tests = method_names.delete_if {|method_name| method_name !~ /^test./}
#Test::Unitが自身のpublicメソッドのうち名前がtestで始まるメソッドを選択している
#
#*現在は以下のようになっていました。
#test-unit/lib/test/unit/testsuitecreator.rb
#  def collect_test_names
#    method_names = @test_case.public_instance_methods(true).collect do |name|
#      name.to_s
#    end
#    test_names = method_names.find_all do |method_name|
#      method_name =~ /^test./ or @test_case.attributes(method_name)[:test]
#    end
#    send("sort_test_names_in_#{@test_case.test_order}_order", test_names)
#  end
# 
#==2.2.2 メソッドを動的に定義する
#Module#define_methodを使えばメソッドをその場で定義出来る
#
#  class MyClass
#    define_method :my_method do |my_arg|
#      my_arg * 3
#    end
#  end
# 
#  obj = MyClass.new
#  obj.my_method(2)   #=> 6
#
#実行時にメソッドを定義するこの技術は動的メソッドと呼ばれる
#
#==2.3 method_missing
#Rubyではコンパイラがメソッド呼び出しを制限することはない
#存在しないメソッドも呼び出せる
#
#  class Lawyer; end
#  
#  nick = Lawyer.new
#  nick.talk_simple
#  
#  => undefined method `talk_simple' for #<Lawyer:0x007fc989053bd8> (NoMethodError)
#  
#talk_simpleを呼び出して、メソッド探索の結果見つからなければ元のレシーバである
#nickのmethod_missing()メソッドを呼び出す。
#method_missing()はすべてのオブジェクトが継承するBasicObjectのインスタンスメソッド。
#
#===2.3.1 method_missing()のオーバーライド
#method_missing()まで辿りついたメッセージは呼び出されたメソッド名と呼び出し時の引数とブロックを持っている。
#  class Lawyer
#    def method_missing(method, *args) 
#      puts "#{method}(#{args.join(', ')})を呼び出した"
#      puts "(ブロックを渡した)" if block_given?
#    end
#  end
#
#  bob = Lawyer.new
#
#  bob.talk_simple('a','b') do
#    # hoge
#  end
#
#  bob.talk_simple('a')
#  
#  => talk_simple(a, b)を呼び出した
#     (ブロックを渡した)
#     talk_simple(a)を呼び出した
#
#==2.3.2 ゴーストメソッド
#method_missing()で処理されたメッセージは、呼び出し側からは通常の呼び出しのように見えるが、
#レシーバには対応するメソッドは見当たらない。これはゴーストメソッドと呼ばれる
#
#===Ruportの例
#
#  require 'ruport'
#
#  table = Ruport::Data::Table.new :column_names => ["country", "wine"],
#                                  :data         => [["France", "Bordeaux"],
#                                                    ["Italy", "Chianti"],
#                                                    ["France", "Chablis"]]
#
#  puts table.to_text
#
#  found = table.rows_with_country("France")
#  found.each do |row|
#    puts row.to_csv
#  end
#
#rows_with_country()もto_csv()もゴーストメソッド
#
#ruport-1.6.3/lib/ruport/data/table.rb
#  def method_missing(id,*args,&block)
#   return as($1.to_sym,*args,&block) if id.to_s =~ /^to_(.*)/ 
#   return rows_with($1.to_sym => args[0]) if id.to_s =~ /^rows_with_(.*)/
#   super
#  end
#
#Ruportを使って新しい出力形式（xsl）やカラム（price）を定義すると
#to_xls()メソッドやrows_with_price()メソッドが手に入る。
#
#==2.3.2 動的プロキシ
#===Flickrの例
#  # Takes a Flickr API method name and set of parameters; returns an XmlSimple object with the response
#  def request(method, *params)
#    response = XmlSimple.xml_in(http_get(request_url(method, params)), { 'ForceArray' => false })
#    raise response['err']['msg'] if response['stat'] != 'ok'
#    response
#  end
#
#  def method_missing(method_id, *params)
#    request(method_id.id2name.gsub(/_/, '.'), params[0])
#  end
#
#Flickr#method_missing()はメソッド名のアンダースコアをすべてドットに変換する。
#メソッド名の引数は配列引数で受け取るので、メソッド名と引数をFlickr#request()に委譲する。
#HTTP経由でFlickrを呼び出し、返ってきたXMLのエラーをチェックして最終的にはそれを返す。
#
#オブジェクトがゴーストメソッドを受け取り、なんらかのロジックを適用してから、他のオブジェクトに
#転送することを動的プロキシと呼ぶ。
#
#
#==ブランクスレート
#Objectクラスよりもメソッドの少ないクラスのこと
#ゴーストメソッドが本物のメソッドの名前と衝突してしまう場合に使用する。
#継承した（必要ない）メソッドを削除して実現する。
#
#===Builderの例
# https://github.com/jimweirich/builder/blob/master/lib/blankslate.rb
#
#BasicObjectを直接継承したクラスは自動的にブランクスレートになる
# 
#===予約済みメソッド
#__send__()と__id__()
#
#これらはsend()とid()の同義語。
#これらを削除したり再定義するとRubyが安易に触れないように警告を出す。
#Test::Unitのようなライブラリは無茶なクライアントコードから身を守るため
#予約済みメソッドを呼び出している
#
class TechPjRuby
end
