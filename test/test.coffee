gp = require '../groupby'

Chain = gp.Chain
ChainMap = gp.ChainMap

chain = Chain.readArray [1..10]

console.log chain.get(0)
console.log chain.get(5)
console.log chain.get(9)

console.log chain.toArray()

console.log "remove:", chain.get(5).remove()

console.log chain.toArray()
console.log "chain node count:#{chain.count()}"

chains = chain.get(5).cut()

console.log "cut:", chains, chains[0].tail(), chains[1].tail()

chain.tail().join(chains[1])
chain.get(4).join(new Chain(6))
console.log "join:", chain.toArray()

chains = chain.divide(4)
console.log "divide:", chains
serise = new Chain('root')

hasOwnProp = {}.hasOwnProperty

addChainToTree = (tree, chain)->
  while chain? and tree?
    s = tree.findFirst chain.value, (a, b)-> a.value is b
    if s is null
      s = tree.addTail
        value: chain.value
        chain: new Chain('root')
    if chain.isTail()
      break
    chain = chain.next()
    tree = s.value.chain
  return

for item in chains
  addChainToTree serise, item.head()
  addChainToTree serise, item.head()

serise = serise.next()
serise.get(0).remove()

console.log serise.toArray()

#cmap = new ChainMap()
#cmap.add(Chain.readArray([1..3]),1)
#cmap.add(Chain.readArray([1..3]),2)
#cmap.add(Chain.readArray([3..5]),3)
#
#console.log cmap

#call(method).then(method).then(method).try(method).done(1,2,3)



