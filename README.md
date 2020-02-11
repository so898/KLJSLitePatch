# KLJSLitePatch

KLJSLitePatch is another [JSPatch](https://github.com/bang590/JSPatch) similar implementation.

The purpose of this project is providing an **App Store Safe** & **JSPatch similar** way to distribute hotfix for iOS/macOS application.

## How to use

It is very simple to use KLJSLitePatch.

### Step 1 - Configuration

First, there are three things you might want to config. Remember, all three configurations are optinal.

1. Config Logger

```objc
[KLJSLitePatchMain registerLogInstance:[Logger new]];
```

You might want to change the NSLog & NSAssert method in default logger.

2. Config Swizzle Method

```objc
[KLJSLitePatchMain registerSwizzleInstance:[Swizzle new]];
```

KLJSLitePatch allows you change default swizzle method implememtation.

There is two implementation in Demo project. One implements with [Aspects](https://github.com/steipete/Aspects), other implements with [Stinger](https://github.com/eleme/Stinger).

3. Config Script Verification & Script Encode

```objc
[KLJSLitePatchMain registerScriptInstance:[Script new]];
```

You should implement script verification & script encode method for your JS script. You do not want your customer run unknow JS script in your application, which will cause a lot of security problems.

### Step 2 - Inject JS Function

After configuration, you could Inject JS Function and load KLJSLitePatch.js script to your appliation.

```objc
[KLJSLitePatchMain injectJSFunc];
```

If there is not exception, you are ready to go.

### Step 3 - Build JS Hotfix Script

So we assume there is a problem in this function:

```objc
@interface TestObject : NSObject
- (NSInteger)returnFunction:(NSInteger)input;
@end

@implementation TestObject
- (NSInteger)returnFunction:(NSInteger)input
{
    return input + 12;
}
@end
```

We could build a script like this:

```javascript
fixMethod('TestObject', 'instead', {
    returnFunction: function(input) {
        return input*12
    }
})
```

There are more examples in `fix.js` of demo project.

### Step 4 - Patch Hotfix

When you receiving Patch from your server, you could load the patch into application via these simple functions:

```objc
[KLJSLitePatchMain evaluateScriptWithPath:path];
[KLJSLitePatchMain evaluateScript:script];
```

The functions will process the script with your Script Verification & Script Decode before apply patch to your application.

You should check your script locally with your device before destribute your patch.

**I am not responsiable for correcting your script, you are on your own!**

### Step 5 - ...

These is no step 5!

You may want to monitor the crash or other thing by yourself. For me, [Visual Studio App Center](https://appcenter.ms) is good enough.

## Implementation

This project is very simple, I implemented this in two days.

The project could by devided into three parts.

### JS Bridge

I implement JS bridge in `KLJSLitePatchMain.m`.

The `injectJSFunc` function inject some JS bridge function into JavaScript enverioment in application. After injetion, JS script could send/receive vriable from native code.

The main problem of the JS bridge is veriable type. JS script will throw JSValue via JS bridge, so I need to convert JSValue to right native type.

I don't want to implement something like JSPatch which convert almost everything between JS and native code. I just do types support by system. Which means type like CGRect, SEL is not supported by KLJSLitePatch. 

I personally remove block support in this project. If your hotfix contais block function, you should release another version of your application. Playing with block and weak strong varible is very dangrous, there will be leak.

The other thing about JS bridge is call method of instance.

I use `performSelector:withObject:withObject:` to implement this feature. So you can only call method within two paramaters. I don't want to use runtime to get method which JSPatch dose. I think one of the reason JSPatch is not allowed in App Store is abusing objc runtime.

This project must be App Store safe, so runtime is limited.

### JS Script

I am using JSPatch for a very long time before my application has been removed from App Store. (Yes, I have an App with JSPatch which hotfix update for more than 1 year) So I want to use KLJSLitePatch in the same way as JSPatch or at less similar.

So I build a JS script or I should say, I slice `JSPatch.js` to `KLJSLitePatch.js`.

Mapping native methods into JS methods is a very good idea. However, JSPatch implements this with runtime, so I do this in a ligh way.

In my experience, most time my hotfix script using perporty of `self`, so I keep `self` method mapping and remove others. In this case, I could solve most problem without bothering runtime.

After checking the API of Aspects & Stinger, I implement `position` in the `fixMethod`, this will help to implement hotfix before a function or after.

### Swizzle Method

I really do not want to bother runtime, but there is no way to get around.

It's good to know that Aspects is using wildly by Apps in App Store. So there should be no problem if you using runtime to do swizzle method.

Aspects and Stinger are good. I do not use them in my project and I do not want to add one of them into my project. So I implement swizzle method by myself.

As some kind of master of JSPatch, I implement it by JSPatch way.

I remove some type support and a lot of useless convert code. The rest of the code is working, but I am afraid there is something not good for App Store. There are so many different between normal Swizzle method code and my code. I don't want to receive any issue about App Store Review problem, so I implement a marco `KLMAXSAFE`.

If you want to use Aspects or Stinger or your own swizzle method implementation, you could change `KLMAXSAFE` to 1. This will remove my swizzle method implementation from compile processing, you're safe to go.

## Other things

As I said, I build this project in two days. There should be a lot of bugs in this, I will fix them in the later days.

I do not think there will be anyone using this project, so I write this README. If thing changed, I will try to write another one...

If you have any suggestions, please open an issue or contact me via <so89898@gmail.com>. Of course, all pull requests are wellcome.

Thanks for reading.
