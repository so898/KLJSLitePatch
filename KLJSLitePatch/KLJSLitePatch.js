var global = this

;(function(){

    varcallbacks = {}
    varcallbackID = 0
  
    var _methodFunc = function(instance, methodName, args) {
        return _OC_callMethod(instance, methodName, args);
    }

    Object.defineProperty(Object.prototype, "__c", {value: function(methodName){
        if(this instanceof Boolean){
            return function(){
                return false
            }
        }

        var self = this
        if(methodName=='super'){
            return function(){
                _OC_invoke(self.__invocation)
            }
        }
                          
        return function(){
            var args = Array.prototype.slice.call(arguments)
            return _methodFunc(self, methodName, args)
        }
    }, configurable:false, enumerable:false})

    var _formatDefineMethods = function(methods, newMethods){
        for(var methodName in methods){
            (
                function(){
                    var originMethod = methods[methodName]
                    newMethods[methodName] = [originMethod.length, function(instance, invocation, args){
                        var lastSelf = global.self
                        var ret;
                        try{
                            var slf = instance;
                            slf.__invocation = invocation;
                            global.self = slf
                            ret = originMethod.apply(originMethod, args)
                            global.self = lastSelf
                        } catch(e) {
                            _OC_catch(e.message,e.stack)
                        }
                        return ret
                    }]
                }
            )()
        }
    }

    global.fixMethod = function(className, position, instMethods, clsMethods){
        var check = _OC_hasClass(className)
        if (check["has"] != 1){
            _OC_error("fixMethod - Class not exist")
            return
        }
        var option=-1;
        switch(position.toLowerCase()){
            case 'after':
                option=0;
                break
            case 'instead':
                option=1;
                break
            case 'before':
                option=2;
                break
            default:
                _OC_error("Wrongmethodoption")
                return
        }

        var newInstMethods = {}, newClsMethods = {}
        _formatDefineMethods(instMethods,newInstMethods)
        _formatDefineMethods(clsMethods,newClsMethods)

        var ret = _OC_fixMethod(className, option, newInstMethods, newClsMethods)
    }

    global.classMethod = function(className, selectorName=null, obj1=null, obj2=null){
        var check = _OC_hasClass(className)
        if (check["has"] != 1){
            _OC_error("classMethod-Classnotexist")
            return
        }
        if (selectorName.length == 0){
            _OC_error("classMethod-selectorNameisnull")
            return
        }
        var ret =_OC_classMethod(className, selectorName, obj1, obj2)
        return ret
    }

    global.instanceMethod = function(instance, selectorName=null, obj1=null, obj2=null){
        if(selectorName.length == 0){
            _OC_error("instanceMethod-selectorNameisnull")
            return
        }
        var ret = _OC_instanceMethod(instance, selectorName, obj1, obj2)
        return ret
    }

    global.logger = function(msg){
        _OC_print(msg)
    }
})()
