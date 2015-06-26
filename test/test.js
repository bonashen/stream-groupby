// Generated by CoffeeScript 1.9.3
var Chain, ChainMap, addChainToTree, chain, chains, gp, hasOwnProp, i, item, len, serise;

gp = require('../groupby');

Chain = gp.Chain;

ChainMap = gp.ChainMap;

chain = Chain.readArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

console.log(chain.get(0));

console.log(chain.get(5));

console.log(chain.get(9));

console.log(chain.toArray());

console.log("remove:", chain.get(5).remove());

console.log(chain.toArray());

console.log("chain node count:" + (chain.count()));

chains = chain.get(5).cut();

console.log("cut:", chains, chains[0].tail(), chains[1].tail());

chain.tail().join(chains[1]);

chain.get(4).join(new Chain(6));

console.log("join:", chain.toArray());

chains = chain.divide(4);

console.log("divide:", chains);

serise = new Chain('root');

hasOwnProp = {}.hasOwnProperty;

addChainToTree = function(tree, chain) {
  var s;
  while ((chain != null) && (tree != null)) {
    s = tree.findFirst(chain.value, function(a, b) {
      return a.value === b;
    });
    if (s === null) {
      s = tree.addTail({
        value: chain.value,
        chain: new Chain('root')
      });
    }
    if (chain.isTail()) {
      break;
    }
    chain = chain.next();
    tree = s.value.chain;
  }
};

for (i = 0, len = chains.length; i < len; i++) {
  item = chains[i];
  addChainToTree(serise, item.head());
  addChainToTree(serise, item.head());
}

serise = serise.next();

serise.get(0).remove();

console.log(serise.toArray());

//# sourceMappingURL=test.js.map