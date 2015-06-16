#groupby for stream json object
through = require 'through'
SortMap = require('sortset').SortMap

exports = module.exports=groupBy = (ruler)->
  write = (doc)->

  end = ->

  s = through(write,end)

  s

