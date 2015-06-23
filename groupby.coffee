#groupby for stream json object
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
    if @isHead() then 1 else 1+@previous().orderNumber()

  previous: ->
    @left
  next:->
    @right
  isHead:->
    @left is null
  isTail:->
    @right is null
  forEach:->

  insert:(item)->

  remove:(item)->

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

