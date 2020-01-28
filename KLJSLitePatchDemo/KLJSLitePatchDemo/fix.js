/**
 * Filename: fix.js
 * Example of fix with js script
 * [This script is not encrypted]
 */

// Replace original methods with new method in js
fixMethod('TestObject', 'instead', {
    pubInvFuncWithParam_integer_ : function(string, integer) {
        logger('NEW' + string + integer);
        var i = self.string();
        logger(i)
        self.setString("ABC");
        var j = self.returnString_("TETETETETE")
        logger(j)
        self.super()
    },
    returnValue: function() {
        return"XYZ"
    },
    returnFunction: function(input) {
        return input*12
    }
})

// Add processing after original methods
fixMethod('TestObject', 'after', {
    pubInvFunc: function() {
        logger('NEW-XXXX');
    },
},{
    pubClsFunc: function() {
        logger('NEW-XXXX');
    }
})
