/*
 * Copyright 2008 Dominic Cooney.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 */


#import "JavaScriptEffect.h"

#include "v8.h"


@interface NSString (V8)

+ (NSString *)stringWithV8String:(v8::Handle<v8::String>) v8String;
- (v8::Local<v8::String>) v8String;

@end


@implementation NSString (V8)

+ (NSString *)stringWithV8String:(v8::Handle<v8::String>) v8String {
  char *cString = (char *) malloc(sizeof(char) * v8String->Utf8Length());
  v8String->WriteUtf8(cString);
  NSString *nsString = [NSString stringWithUTF8String:cString];
  free(cString);
  return nsString;
}

- (v8::Local<v8::String>)v8String {
  // need to encode the string as NSData to determine its encoded length
  NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
  return v8::String::New((const char*) [data bytes], [data length]);  
}

@end


@protocol JavaScriptEffectCallback

- (void)fire:(JavaScriptEffect*)sender;

@end


@interface JavaScriptEffect (Private)

- (void)initGlobalContext;
- (void)evaluateScript:(NSString *)script;
- (void)addPendingCallback:(id<JavaScriptEffectCallback>)callback;
- (void)logException:(v8::Handle<v8::String>)message;
- (void)setKey:(NSUInteger)keyCode
             r:(double)r g:(double)g b:(double)b a:(double)a;
- (void)getKey:(NSUInteger)keyCode
             r:(CGFloat *)r g:(CGFloat *)g b:(CGFloat *)b a:(CGFloat *)a
          down:(BOOL *)down up:(BOOL *)up isPressed:(BOOL *)isPressed;

@property (readonly) v8::Persistent<v8::Context> globalContext;

@end


JavaScriptEffect *getEffectFromArguments(const v8::Arguments &arguments) {
  return (JavaScriptEffect*) v8::External::Unwrap(arguments.Data());
}


typedef enum {
  kDownloadInProgress,
  kDownloadSuceeded,
  kDownloadFailed
} DownloadStatus;


@interface DownloadCallback : NSObject<JavaScriptEffectCallback> {
  JavaScriptEffect *owner;
  v8::Persistent<v8::Object> callbacks;
  NSError *error;
  NSMutableData *buffer;
  NSStringEncoding encoding;
  DownloadStatus status;
}
- (id)initWithEffect:(JavaScriptEffect *)effect
                 url:(NSString*)url
           callbacks:(v8::Handle<v8::Object>)callbacks;
@end


@implementation DownloadCallback

- (id)initWithEffect:(JavaScriptEffect *)effect
                 url:(NSString *)url
           callbacks:(v8::Handle<v8::Object>)theCallbacks {
  self = [super init];
  if (self) {
    owner = [effect retain];
    callbacks = v8::Persistent<v8::Object>::New(theCallbacks);
    buffer = [[NSMutableData dataWithCapacity:0] retain];
    error = nil;
    status = kDownloadInProgress;
    
    NSURLRequest *request =
        [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection connectionWithRequest:request delegate:self];
  }
  return self;
}

- (void)dealloc {
  [owner release];
  [buffer release];
  [error release];
  callbacks.Dispose();
  callbacks = v8::Persistent<v8::Object>();
  [super dealloc];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
  encoding = CFStringConvertEncodingToNSStringEncoding(
      CFStringConvertIANACharSetNameToEncoding(
          (CFStringRef)[response textEncodingName]));
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  status = kDownloadSuceeded;
  [self fire:owner];
  [owner release];
  owner = nil;
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)theError {
  error = [theError retain];
  status = kDownloadFailed;
  [self fire:owner];  
  [owner release];
  owner = nil;
}

- (void) fire:(JavaScriptEffect *)sender {
  if ([sender visible]) {
    v8::Context::Scope contextScope([sender globalContext]);
    v8::HandleScope handleScope;
    v8::TryCatch tryCatch;
    v8::Local<v8::String> functionName;
    
    if (status == kDownloadSuceeded) {
      // look up the onComplete callback
      functionName = v8::String::NewSymbol("onComplete");
      v8::Local<v8::Value> onComplete = callbacks->Get(functionName);
      
      if (onComplete->IsFunction()) {
        // create the data argument; convert the downloaded content to UTF8
        NSString *dataStr =
            [[[NSString alloc] initWithData:buffer
                                   encoding:encoding] autorelease];
        v8::Handle<v8::Value> arguments[] = {
          [dataStr v8String]
        };
        
        // call the function
        v8::Local<v8::Function>::Cast(onComplete)->Call(callbacks, 1,
                                                        arguments);
      }
    } else if (status == kDownloadFailed) {
      // look up the onError callback
      functionName = v8::String::NewSymbol("onError");
      v8::Local<v8::Value> onError = callbacks->Get(functionName);

      if (onError->IsFunction()) {
        v8::Handle<v8::Value> arguments[] = {
          [[error localizedDescription] v8String]
        };
        
        // call the function
        v8::Local<v8::Function>::Cast(onError)->Call(callbacks, 1, arguments);
      }
    } else {
      NSLog(@"unreachable");
    }

cleanUp:  
    if (tryCatch.HasCaught()) {
      [sender logException:tryCatch.Message()->Get()];
    }
    
    [buffer release];
    buffer = nil;
    [error release];
    error = nil;
    callbacks.Dispose();
    callbacks = v8::Persistent<v8::Object>();
  } else {
    [sender addPendingCallback:self];
  }
}

@end


v8::Handle<v8::Value> downloadCallback(const v8::Arguments &arguments) {
  JavaScriptEffect *effect = getEffectFromArguments(arguments);  
  
  if (arguments.Length() < 2) {
    return v8::ThrowException(v8::String::New("download needs two arguments"));
  }
  
  v8::Local<v8::String> jsUrl = arguments[0]->ToString();
  NSString *url = [NSString stringWithV8String:jsUrl];

  if (arguments[1]->IsObject()) {
    v8::Local<v8::Object> callbacks = v8::Local<v8::Object>::Cast(arguments[1]);
    [[DownloadCallback alloc] initWithEffect:effect
                                         url:url
                                   callbacks:callbacks];
  }

  return v8::Undefined();
}


@interface SetTimeoutCallback : NSObject<JavaScriptEffectCallback> {
  v8::Persistent<v8::Function> callback;
}

- (id)initWithEffect:(JavaScriptEffect *)effect
            callback:(v8::Handle<v8::Function>)callback;

@end


@implementation SetTimeoutCallback

- (id) initWithEffect:(JavaScriptEffect *)owner
             callback:(v8::Handle<v8::Function>)function {
  self = [super init];
  if (self) {
    callback = v8::Persistent<v8::Function>::New(function);
  }
  return self;
}

- (void)dealloc {
  callback.Dispose();
  callback = v8::Persistent<v8::Function>();
  [super dealloc];
}

- (void) fire:(JavaScriptEffect *)sender {
  if ([sender visible]) {
    v8::Context::Scope contextScope([sender globalContext]);
    v8::HandleScope handleScope;
    v8::TryCatch tryCatch;
    callback->Call(callback, 0, NULL);
    if (tryCatch.HasCaught()) {
      [sender logException:tryCatch.Message()->Get()];
    }
    callback.Dispose();
    callback = v8::Persistent<v8::Function>();
  } else {
    [sender addPendingCallback:self];
  }
}

@end

v8::Handle<v8::Value> setTimeoutCallback(const v8::Arguments &arguments) {
  JavaScriptEffect *effect = getEffectFromArguments(arguments);  

  if (arguments.Length() < 2) {
    return v8::ThrowException(
        v8::String::New("setTimeout needs two arguments"));
  }
  
  if (!arguments[0]->IsFunction()) {
    return v8::ThrowException(
        v8::String::New("setTimeout's first argument has to be a function"));
  }

  v8::Local<v8::Function> function =
      v8::Local<v8::Function>::Cast(arguments[0]);
  SetTimeoutCallback *callback =
      [[SetTimeoutCallback alloc] initWithEffect:effect callback:function];
  
  double timeMsec = arguments[1]->NumberValue();
  
  [callback performSelector:@selector(fire:)
                 withObject:effect
                 afterDelay:(timeMsec / 1000.0)];

  return v8::Undefined();
}

v8::Handle<v8::Value> logCallback(const v8::Arguments &arguments) {
  JavaScriptEffect *effect = getEffectFromArguments(arguments);
  
  for (int i = 0; i < arguments.Length(); i++) {
    v8::TryCatch tryCatch;
    v8::Local<v8::String> string = arguments[i]->ToString();
    if (tryCatch.HasCaught()) {
      // bail out early if we encounter an exception
      break;
    }
    [[effect loggingDelegate] log:[NSString stringWithV8String:string]
                     withSeverity:kLogSeverityInfo];
  }
  return v8::Undefined();
}

v8::Handle<v8::Value> setColorCallback(const v8::Arguments &arguments) {
  JavaScriptEffect *effect = getEffectFromArguments(arguments);

  NSUInteger keyCode = (NSUInteger) arguments[0]->Uint32Value();

  double components[4];
  for (int i = 0; i < 4; i++) {
    components[i] = arguments[i + 1]->NumberValue();
  }

  [effect setKey:keyCode
               r:components[0]
               g:components[1]
               b:components[2]
               a:components[3]];
  return v8::Undefined();
}

v8::Handle<v8::Value> getColorCallback(const v8::Arguments &arguments) {
  JavaScriptEffect *effect = getEffectFromArguments(arguments);
  
  NSUInteger keyCode = (NSUInteger) arguments[0]->Uint32Value();
  
  CGFloat r, g, b, a;
  BOOL down, up, isPressed;
  [effect getKey:keyCode
               r:&r g:&g b:&b a:&a
            down:&down up:&up isPressed:&isPressed];
  
  v8::Local<v8::Object> state = v8::Object::New();
  state->Set(v8::String::NewSymbol("r"), v8::Number::New(r));
  state->Set(v8::String::NewSymbol("g"), v8::Number::New(g));
  state->Set(v8::String::NewSymbol("b"), v8::Number::New(b));
  state->Set(v8::String::NewSymbol("a"), v8::Number::New(a));
  state->Set(v8::String::NewSymbol("down"), v8::Boolean::New(down));
  state->Set(v8::String::NewSymbol("up"), v8::Boolean::New(up));
  state->Set(v8::String::NewSymbol("isPressed"), v8::Boolean::New(isPressed));
  return state;
}


@implementation JavaScriptEffect (Private)

- (void) initGlobalContext {
  v8::HandleScope handleScope;
  v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
  global->Set(
      v8::String::New("log"),
      v8::FunctionTemplate::New(logCallback, v8::External::New(self)));
  global->Set(
      v8::String::New("download"),
      v8::FunctionTemplate::New(downloadCallback, v8::External::New(self)));
  global->Set(
      v8::String::New("setTimeout"),
      v8::FunctionTemplate::New(setTimeoutCallback, v8::External::New(self)));
  global->Set(
      v8::String::New("__getColor__"),
      v8::FunctionTemplate::New(getColorCallback, v8::External::New(self)));
  global->Set(
      v8::String::New("__setColor__"),
      v8::FunctionTemplate::New(setColorCallback, v8::External::New(self)));
  *((v8::Persistent<v8::Context>*) &globalContext) =
      v8::Context::New(NULL, global);

  // evaluate the built-in library
  NSString *path = [[NSBundle mainBundle] pathForResource:@"library"
                                                   ofType:@"js"];
  NSString *library = [NSString stringWithContentsOfFile:path];
  [self evaluateScript:library];
}

- (void) evaluateScript:(NSString *)script {
  v8::Context::Scope contextScope([self globalContext]);
  v8::TryCatch tryCatch;
  v8::Local<v8::Script> compiledScript =
      v8::Script::Compile([script v8String], v8::Undefined());
  if (compiledScript.IsEmpty()) {
    [self logException:v8::String::New("Syntax error")];
    [self setVisible:NO];
    return;
  }
  compiledScript->Run();
  if (tryCatch.HasCaught()) {
    [self logException:tryCatch.Message()->Get()];
    [self setVisible:NO];
  }
}

- (v8::Persistent<v8::Context>) globalContext {
  // this is fragile if V8 ever makes persistent handles larger than a pointer
  return *reinterpret_cast<v8::Persistent<v8::Context>*>(&globalContext);
}

- (void)addPendingCallback:(id<JavaScriptEffectCallback>)callback {
  [pendingCallbacks addObject:callback];
}

- (void)logException:(v8::Handle<v8::String>)message {
  [loggingDelegate log:[NSString stringWithV8String:message]
          withSeverity:kLogSeverityError];
}

- (void)setKey:(NSUInteger)keyCode
             r:(double)r g:(double)g b:(double)b a:(double)a {
  Key key;
  if ([keyMap keyForScanCode:keyCode key:&key]) {
    [buffer setColorComponentsForKey:key r:r g:g b:b a:a];    
  }
}

- (void)getKey:(NSUInteger)keyCode
             r:(CGFloat *)r g:(CGFloat *)g b:(CGFloat *)b a:(CGFloat *)a
          down:(BOOL *)down up:(BOOL *)up isPressed:(BOOL *)isPressed {
  Key key;
  if ([keyMap keyForScanCode:keyCode key:&key]) {
    [buffer colorComponentsForKey:key r:r g:g b:b a:a];
    *down = keyState[key].down;
    *up = keyState[key].up;
    *isPressed = keyState[key].isPressed;
  }
}

@end


@implementation JavaScriptEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionary];
}

@synthesize source;
@synthesize loggingDelegate;

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"JavaScript"];
    source = @"";
    sourceState = kSourceNeedsEval;
    keyMap = [[KeyMap alloc] init];
    keyState = (KeyState *)calloc(kNumKeys, sizeof(KeyState));
    buffer = [[KeyboardDisplayBuffer alloc] init];
    [self initGlobalContext];
    pendingCallbacks = [[NSMutableSet setWithCapacity:0] retain];
  }
  return self;
}

- (void)dealloc {
  [source release];
  [keyMap release];
  free(keyState);
  [buffer release];
  [pendingCallbacks release];
  [self globalContext].Dispose();
  [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    source = [[coder decodeObjectForKey:@"source"] retain];
    sourceState = kSourceNeedsEval;
    keyMap = [[KeyMap alloc] init];
    keyState = (KeyState *)calloc(kNumKeys, sizeof(KeyState));
    buffer = [[KeyboardDisplayBuffer alloc] init];
    [self initGlobalContext];
    pendingCallbacks = [[NSMutableSet setWithCapacity:0] retain];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:source forKey:@"source"];
}

- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[JavaScriptSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;
}

- (void)setSource:(NSString*)newSource {
  [self willChangeValueForKey:@"source"];
  [newSource retain];
  [source release];
  source = newSource;
  sourceState = kSourceNeedsEval;
  [self didChangeValueForKey:@"source"];
}

- (void)draw:(KeyboardDisplayBuffer *)displayBuffer
      keyMap:(KeyMap *)keyMap
      events:(NSArray *)events {
  if (!source) {
    // NSTextView sets the source to nil when all the text is deleted; when
    // there's no source, there's nothing to do
    return;
  }
  
  v8::HandleScope handleScope;
  
  if (kSourceNeedsEval == sourceState) {
    [self evaluateScript:source];
    sourceState = kSourceEvaluated;
    [pendingCallbacks removeAllObjects];
  }

  // fire pending callbacks first
  for (id<JavaScriptEffectCallback> callback in pendingCallbacks) {
    [callback fire:self];
  }
  [pendingCallbacks removeAllObjects];
  
  // update the keyboard state
  for (int key = (int) kMinKey; key <= (int) kMaxKey; key++) {
    keyState[key].down = keyState[key].up = NO;
  }
  
  for (KeyEvent *event in events) {
    KeyState *state = &keyState[[event key]];
    if ([event down]) {
      state->down =YES;
      state->isPressed = YES;
    } else {
      state->up = YES;
      state->isPressed = NO;
    }
  }
  
  // call the script's 'draw' method
  {
    v8::Context::Scope contextScope([self globalContext]);
    v8::Local<v8::Object> global = [self globalContext]->Global();
    v8::Local<v8::Value> draw = global->Get(v8::String::NewSymbol("draw"));
    if (draw->IsFunction()) {
      v8::TryCatch tryCatch;
      v8::Local<v8::Function>::Cast(draw)->Call(
          v8::Local<v8::Object>::Cast(draw), 0, NULL);
      if (tryCatch.HasCaught()) {
        [self logException:tryCatch.Message()->Get()];
      }
    }
  }
  
  [displayBuffer paintBuffer:buffer];
}

@end


@implementation JavaScriptSettingsViewController

- (id) init {
  return [super initWithNibName:@"JavaScriptSettings" bundle:nil];
}

- (void)awakeFromNib {
  // this sets the font and color so that when the log is cleared messages
  // continue to be set in gray Monaco
  [logTextView setFont:[NSFont fontWithName:@"Monaco" size:11]];
  [logTextView setTextColor:[NSColor disabledControlTextColor]];
}

- (void)setEffect:(Effect *)theEffect {
  JavaScriptEffect *existingEffect = (JavaScriptEffect *)effect;
  if ([existingEffect loggingDelegate] == self) {
    [existingEffect setLoggingDelegate:nil];
  }
  [super setEffect:theEffect];
  [(JavaScriptEffect *)theEffect setLoggingDelegate:self];
}

- (void)log:(NSString *)message withSeverity:(LogSeverity)severity {
  SEL selector = @selector(unsafeLog:withSeverity:);
  NSMethodSignature *signature =
      [[self class] instanceMethodSignatureForSelector:selector];
  NSInvocation *invocation =
      [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:self];
  [invocation setSelector:selector];
  [invocation setArgument:&message atIndex:2];
  [invocation setArgument:&severity atIndex:3];
  [invocation retainArguments];
  [invocation performSelectorOnMainThread:@selector(invoke)
                               withObject:nil
                            waitUntilDone:NO];
}

// must be called on the UI thread
- (void)unsafeLog:(NSString *)message withSeverity:(LogSeverity)severity {
  NSString *formattedMessage = [NSString stringWithFormat:@"%@\r\n", message];
  NSDictionary *attrs;
  
  if (severity == kLogSeverityError) {
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
      [NSColor yellowColor], NSBackgroundColorAttributeName, 
      [NSColor redColor], NSForegroundColorAttributeName,
      nil];
  } else {
    attrs =
        [NSDictionary dictionaryWithObject:[NSColor disabledControlTextColor]
                                    forKey:NSForegroundColorAttributeName];
  }
  NSAttributedString *attrString =
      [[NSAttributedString alloc] initWithString:formattedMessage
                                      attributes:attrs];
  [attrString autorelease];
  NSTextStorage *textStorage = [logTextView textStorage];
  int oldLength = [textStorage length];
  [textStorage appendAttributedString:attrString];
  [logTextView scrollRangeToVisible:NSMakeRange(oldLength, [message length])];
}

- (IBAction) clearLog:(id)sender {
  [logTextView setString:@""];
}

- (IBAction) play:(id)sender {
  if ([effect visible]) {
    // end editing of the text view
    [[[self view] window] makeFirstResponder:self];    
  }
}

@end
