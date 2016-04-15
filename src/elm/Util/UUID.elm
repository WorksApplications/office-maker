module Util.UUID(gen) where
import Random

gen : Task () String

genInt = int 65536 (65536*2-1)

{-
var uuid = (function(){
    var S4 = function() {
        return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
    }
    return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4() +S4());
})();

console.log(uuid);
-}
