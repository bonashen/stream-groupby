#groupby for stream json object
through = require 'through'
SortMap = require('sortset').SortMap
Iterator = require('sortset').Iterator

class grouped
  constructor:->
    @series = []
  iterator:->new Iterator(@series)


class Series
  constructor:->
    @data = new SortMap

generatorRulers = (fields)->
  rulers =
    items:new SortMap
    exec:(doc)->

    add:(ruler)->
      @items.add(ruler.name,ruler)

  if not fields instanceof Array
    fields = fields.split ','

  for field,index in fields
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

exports = module.exports=groupBy = (fields)->
  rulers = generatorRulers(fields)

  write = (doc)->
    ruler.exec(doc)
  end = ->

  s = through(write,end)

  s

