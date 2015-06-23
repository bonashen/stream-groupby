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

class DoubleChain
  constructor:(@value)->
    @left=null
    @right = null
  head:->
    if @isHead() then @ else @left.head()

  tail:->
    if @isTail() then @ else @right.tail()

  orderNumber:->
    if @isHead() then 0 else 1+@previous().orderNumber()

  count:->
    @tail().orderNumber()+1

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
  forEach:(callback)->
    if 'function' is typeof callback
      item = @head()
      while item isnt null and callback(item) in [undefined ,null,false]
        item = item.next()
      return

  get:(pos)->
    ret=null
    @forEach (item)->
      if item.orderNumber()==pos
        ret = item
        true
    ret
# insert before self
  insert:(value)->
    right = @
    if right.isHead()
      dc = @addHead()
      dc.value = value
    else
      dc= new DoubleChain(value)
      dc.left = right.left
      dc.right = right
      right.left.right=dc
      right.left = dc
    dc

  remove:->
    item = @
    if @count()>1 and @indexOf(item)>-1
      if item.isHead()
        item.right.left = null
      else
        item.right.left = item.right

      if item.isTail()
        item.left.right = null
      else
        item.left.right = item.right


  addHead:->
    ret = new DoubleChain
    ret.right=@head()
    ret.left=null
    @head().left = ret
    ret
  addTail:->
    ret  = new DoubleChain
    ret.left=@tail()
    ret.right=null
    @tail().right = ret
    ret

DoubleChain.factory =(array)->
  head = new DoubleChain
  if array instanceof Array and array.length
    for item in array
      head.addTail().value = item
  ret = head.next()
  head.remove()
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

    Iterator.forEach iterator,(doc)->
      d_series=@rulers.exec(doc)
      d_series.reverse()
      pre_series = null
      Iterator.forEach(d_series,(data)->
        series =
          left:null
          right: null
          key: data.key
          value: data.value
          details:[]
          top:->
            if @left isnt null
              @
            else
              @left.top()
          tail:->
            if @right isnt null
              @
            else
              @right.tail()
        if not pre_series?
          series.details.push doc
        if pre_series?
          series.right = pre_series
          pre_series.left= series
        pre_series = series
      )



#分组数据
class Series
  constructor:->
    @data = new SortMap
    @docs = [] #{series:series,doc:doc}

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

exports = module.exports=groupBy = (option)->
  rulers = generatorRulers(option)

  new Packet(rulers)

#  write = (doc)->
#    ruler.exec(doc)
#  end = ->
#
#  s = through(write,end)
#
#  s

