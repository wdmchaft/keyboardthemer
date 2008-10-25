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

// An effect that uses JavaScriptCore to execute user scripts which color keys.

#import <Cocoa/Cocoa.h>

#import "Effect.h"


typedef enum {
  kLogSeverityInfo,
  kLogSeverityError
} LogSeverity;


@protocol Logger

- (void)log:(NSString *)message withSeverity:(LogSeverity)severity;

@end


typedef enum {
  kSourceNeedsEval,
  kSourceEvaluated
} SourceState;


typedef struct {
  BOOL down;
  BOOL up;
  BOOL isPressed;
} KeyState;


@interface JavaScriptEffect : Effect {
  NSString *source;
  id<Logger> loggingDelegate;
@private
  KeyMap *keyMap;
  KeyState *keyState;
  KeyboardDisplayBuffer* buffer;
  SourceState sourceState;
  void *globalContext;  // actually v8::Persistent<v8::Context>
  NSMutableSet *pendingCallbacks;
}

@property (retain, readonly, nonatomic) NSString* source;
@property (assign, nonatomic) id<Logger> loggingDelegate;

+ (NSDictionary *)undoProperties;

@end

@interface JavaScriptSettingsViewController
    : EffectSettingsViewController<Logger> {
  IBOutlet NSTextView *logTextView;
}

- (IBAction) clearLog:(id)sender;
- (IBAction) play:(id)sender;

@end
