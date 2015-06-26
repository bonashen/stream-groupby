#groupby for stream json object
# grouppby = require 'stream-groupby'
# groupby("name,age",function(){}).stream()
# groupby("name,age",function(){}).readArray([])
# groupby("name,age",function(){}).readIterator(new Iterator)
# groupby([{name:'serise1',exec:function(){}}]).stream()
# groupby([{name:'serise1',key:'name'},{name:'serise2',key:'age'}]).stream()


through = require 'through'
SortMap = require('sortset').SortMap
Iterator = require('sortset').Iterator
st = require "stream-total"

#设计思路
# 分组条件（分组规则)----->分组数据 ----->分组统计与遍历

# example(使用样例):
# groupBy("name,age").stream(template) //for stream

# groupBy("name,age").readArray([]).total({})
# groupBy("name,age").readIterator(new Iterator([])).total({})
# groupBy("name,age").readIterator(new Iterator([])).total({})
# groupBy("name,age").readArray([]).forEach(function(){})

exports = module.exports=groupBy = (option)->
  rulers = generatorRulers(option)
  new Packet(rulers)

class DoubleChain
  constructor:(@value)->
    @left=null
    @right = null
  head:->
    if @isHead() then @ else @left.head()

  tail:->
    if @isTail() then @ else @right.tail()
  #当前节点顺序号
  orderNumber:->
    if @isHead() then 0 else 1+@previous().orderNumber()
  #取链节点数
  count:->
    @tail().orderNumber()+1
  #定位item在链中的位置，返回x>-1
  indexOf:(item)->
    ret = -1
    if item isnt null
      @forEach (i)->
        if i is item
          ret = i.orderNumber()
          true
    ret

  previous: ->
    @left
  next:->
    @right
  isHead:->
    @left is null
  isTail:->
    @right is null
  #遍历链的节点
  forEach:(callback)->
    if 'function' is typeof callback
      item = @head()
      while item isnt null and callback(item) in [undefined ,null,false]
        item = item.next()
      return

  #获取pos顺序的节点
  get:(pos)->
    ret=null
    @forEach (item)->
      if item.orderNumber()==pos
        ret = item
        true
    ret

  #将chain链接到当前节点的后面
  join:(chain)->
    if @indexOf(chain)<0
      rightHead = chain.head()
      rightTail = chain.tail()
      rightHead.left = @
      rightTail.right = @right
      if not @isTail()
        @right.left = rightTail
      @right = rightHead
      true
    else
      false
  #按len等分链
  divide:(len)->
    ret = []
    d_count = @count()
    head = @head()
    if d_count>=len and len>0
      j=0
      num = Math.floor(d_count/len)
      while j<num
        if head isnt null
          ret.push head
        item = head
        i=0
        while i<len and item isnt null
          i++
          item = item.next()
        head = item
        if head isnt null
          head.cut()
        j++
    if d_count%len>0
      ret.push head
    ret
  #以当前节点为头，分隔为两个链，返回两个链的头节点
  cut:->
    item = @
    if item.isHead()
      return [item]
    ret = [item.head()]
    item.left.right = null
    item.left = null
    ret.push item
    ret
  #从链中移除当前节点
  remove:->
    item = @
    if @count()>1 #and @indexOf(item)>-1
      if item.isHead()
        item.right.left = null
      else
        if not item.isTail()
          item.right.left = item.left

      if item.isTail()
          item.left.right = null
      else
        if not item.isHead()
          item.left.right = item.right
    item.left = item.right = null
    item
  #在链头部增加一个节点
  addHead:(value)->
    ret = new DoubleChain(value)
    ret.right=@head()
    ret.left=null
    @head().left = ret
    ret
  #在链尾部增加一个节点
  addTail:(value)->
    ret  = new DoubleChain(value)
    ret.left=@tail()
    ret.right=null
    @tail().right = ret
    ret
  #将当前节点所处的链节点值转存为数组
  toArray:->
    ret=[]
    @forEach (item)->
      ret.push(item.value)
      false
    ret
  #克隆当前节点所处的链
  clone:->
    ret = @toArray()
    head = new DoubleChain(ret.shift())
    for item in ret
      head.addTail().value = item
    ret = head

  find:(value,eq)->
    eq = eq||(a,b)->  a is b
    ret=[]
    @forEach (item)->
      if eq(item.value,value)
        ret.push item
    ret

  findFirst:(value,eq)->
    eq = eq||(a,b)->  a is b
    ret=null
    @forEach (item)->
      if eq(item.value,value)
        ret= item
        true
    ret

DoubleChain.readArray =(array)->
  head = new DoubleChain
  if array instanceof Array and array.length
    for item in array
      head.addTail().value = item
  ret = head.next()
  head.remove()
  ret

class ChainMap extends SortMap
  compare:(a,b)->
    a = a.key.head()
    b = b.key.head()
    ret = 1
    a.forEach (a_item)->
      b_item = b.get a_item.orderNumber()
      ret = if  a_item.value> b_item.value then 1 else if a_item.value<b_item.value then -1 else 0
      ret !=0
    ret


#分组器，读取数据并进行分组
class Packet
  constructor:(@rulers)->
    @series= new Series
# for stream,like @readIterator(iterator).total(template)
  stream:(template)->

  readArray:(array)->
    return @readIterator(new Iterator(array))

  readIterator:(iterator)->
    root = new DoubleChain("root")
    Iterator.forEach iterator,(doc)->
      d_series=@rulers.exec(doc)
      root.tail().join DoubleChain.readArray(d_series)
      root.tail().doc = doc
      false
    head = root.next()
    root.remove()

#分组数据
class Series
  constructor:->
    @data = new ChainMap

  total:(template)->

  forEach:(callback)->

generatorRulers = (option)->
  rulers =
    items:new SortMap
    exec:(doc)->
      ret = []
      @items.forEach (key,ruler)->
        ret.push
          name:key
          value:ruler.exec(doc)
      ret
    add:(ruler)->
      @items.add(ruler.name,ruler)
    count:->
      @items.size


  if not option instanceof Array
    option = option.split ','

  for field,index in option
    ruler =
      name:field
      exec:(doc)->
        doc[@name]

    if 'function'==typeof field
      ruler =
        name:"Series #{index}"
        exec:field
    rulers.add ruler
  rulers



#  write = (doc)->
#    ruler.exec(doc)
#  end = ->
#
#  s = through(write,end)
#
#  s

exports.Chain = DoubleChain
exports.ChainMap = ChainMap