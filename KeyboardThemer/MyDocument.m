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

#import "MyDocument.h"

#import "AppleScriptEffect.h"
#import "Effect.h"
#import "HeatMapEffect.h"
#import "JavaScriptEffect.h"
#import "KeyboardManager.h"
#import "LifeEffect.h"
#import "MatrixEffect.h"
#import "PlasmaEffect.h"


NSString *EffectPasteboardType = @"Keyboard Themer Effect";


@implementation MyDocument

@synthesize appliedEffects;
@synthesize availableEffects;

- (id)init
{
  self = [super init];
  if (self) {
    LifeEffect* lifeEffect = [[LifeEffect alloc] init];
    HeatMapEffect* heatMapEffect = [[HeatMapEffect alloc] init];
    PlasmaEffect *plasmaEffect = [[PlasmaEffect alloc] init];
    JavaScriptEffect* javaScriptEffect = [[JavaScriptEffect alloc] init];
    AppleScriptEffect* appleScriptEffect = [[AppleScriptEffect alloc] init];
    MatrixEffect* matrixEffect = [[MatrixEffect alloc] init];

    availableEffects = [NSArray arrayWithObjects:lifeEffect,
                                                 heatMapEffect,
                                                 plasmaEffect,
                                                 matrixEffect,
                                                 javaScriptEffect,
                                                 appleScriptEffect,
                                                 nil];

    // hard-wire the first effect
    appliedEffects = [[LayerEffect alloc] init];
    [[appliedEffects arrangedEffects] addObject:[[LifeEffect alloc] init]];
  }
  return self;
}

- (Effect *)selectedEffect {
  NSArray *selectedObjects = [appliedEffectsController selectedObjects];
  return [selectedObjects count]
  ? (Effect *)[selectedObjects objectAtIndex:0]
  : nil; 
}

- (void) selectedEffectChanged {
  Effect *selectedEffect = [self selectedEffect];
  NSViewController* viewController = selectedEffect
      ? [selectedEffect createViewController]
      : [[NoSettingsViewController alloc] init];

  NSView *v = [viewController view];
  NSWindow* w = [settingsBox window];
  NSSize oldBoxSize = [[settingsBox contentView] frame].size;
  NSSize newBoxSize = [v frame].size;
  float deltaWidth = newBoxSize.width - oldBoxSize.width;
  float deltaHeight = newBoxSize.height - oldBoxSize.height;
  NSRect windowFrame = [w frame];
  NSSize oldWindowSize = windowFrame.size;
  windowFrame.size.width = MAX(oldWindowSize.width + deltaWidth,
                               [w minSize].width);
  windowFrame.size.height = MAX(oldWindowSize.height + deltaHeight,
                                [w minSize].height);
  float actualDeltaWidth = windowFrame.size.width - oldWindowSize.width;
  float actualDeltaHeight = windowFrame.size.height - oldWindowSize.height;
  windowFrame.origin.x -= actualDeltaWidth / 2;
  windowFrame.origin.y -= actualDeltaHeight / 2;
  
  // clear the box for resizing
  [settingsBox setContentView:nil];
  [w setFrame:windowFrame display:YES animate:YES];
  
  [settingsBox setContentView:v];    
}

- (void) awakeFromNib {
  // TODO: move this to the application delegate
  [NSColor setIgnoresAlpha:NO];
  
  [appliedEffectsView registerForDraggedTypes:
   [NSArray arrayWithObject:[Effect pasteboardType]]];
  
  [keyboardManagerController setContent:[KeyboardManager sharedInstance]];
  
  [[KeyboardManager sharedInstance] addObserver:self
                                     forKeyPath:@"keyboard"
                                        options:(NSKeyValueObservingOptionNew
                                                 | NSKeyValueObservingOptionOld)
                                        context:nil];
  
  [appliedEffectsController addObserver:self
                             forKeyPath:@"selectedObjects"
                                options:NSKeyValueObservingOptionNew
                                context:nil];
  
  [[NSApplication sharedApplication]
      addObserver:self
       forKeyPath:@"mainWindow.windowController.document"
          options:NSKeyValueObservingOptionNew
          context:nil];
  
  // tickle the selected effect so the effect's settings are shown
  [self selectedEffectChanged];
  
  // hook up the first effect to undo/redo
  [self startObservingEffect:[self selectedEffect]];
}

- (void)close {
  Keyboard *keyboard = [[KeyboardManager sharedInstance] keyboard];
  if (keyboard && [keyboard effect] == appliedEffects) {
    [keyboard setEffect:nil];
  }

  [[KeyboardManager sharedInstance] removeObserver:self forKeyPath:@"keyboard"];
  [appliedEffectsController removeObserver:self forKeyPath:@"selectedObjects"];
  [[NSApplication sharedApplication]
      removeObserver:self
      forKeyPath:@"mainWindow.windowController.document"];
  
  
  [super close];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  NSLog(@"observing change in path '%@'", keyPath);
  if (object == appliedEffectsController
      && [keyPath isEqual:@"selectedObjects"]) {
    [self selectedEffectChanged];
  } else if ([keyPath isEqual:@"keyboard"]) {
    Keyboard *oldKeyboard = [change objectForKey:NSKeyValueChangeOldKey];
    if ((id)oldKeyboard != [NSNull null]
        && [oldKeyboard effect] == appliedEffects) {
      [oldKeyboard setEffect:nil];
    }
    
    Keyboard *newKeyboard = [change objectForKey:NSKeyValueChangeNewKey];
    if ((id)newKeyboard != [NSNull null]) {
      [newKeyboard setEffect:appliedEffects];
    }
  } else if ([keyPath isEqual:@"mainWindow.windowController.document"]) {
    Keyboard *keyboard = [[KeyboardManager sharedInstance] keyboard];
    if ([change objectForKey:NSKeyValueChangeNewKey] == self
        && keyboard
        && [keyboard effect] != appliedEffects) {
      [keyboard setEffect:appliedEffects];
    }
  } else {
    // assume the changed property is an effect property registered for
    // undo/redo
    
    NSUndoManager *undo = [self undoManager];
    Effect *effect = (Effect *)object;
    if ([@"visible" isEqual:keyPath]) {
      BOOL visible;
      NSValue *newValue = (NSValue *)[change objectForKey:NSKeyValueChangeNewKey];
      [newValue getValue:&visible];
      BOOL old = !visible;
      [[undo prepareWithInvocationTarget:effect] setVisible:old];
      if (![undo isUndoing]) {
        [undo setActionName:
         [NSString stringWithFormat:(visible ? @"Show %@" : @"Hide %@"),
          [effect name]]];
      }
    } else {
      // assume a KVO observed property
      id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
      SEL selector = @selector(setValue:forKeyPath:);
      NSMethodSignature *signature =
          [effect methodSignatureForSelector:selector];
      NSInvocation *invocation =
          [NSInvocation invocationWithMethodSignature:signature];
      [invocation setSelector:selector];
      [invocation setArgument:&oldValue atIndex:2];
      [invocation setArgument:&keyPath atIndex:3];
      [undo prepareWithInvocationTarget:effect];
      [undo forwardInvocation:invocation];
      if (![undo isUndoing]) {
        [undo setActionName:
         [NSString stringWithFormat:@"Edit %@", (NSString *)context]];
      }
    }
  }
}

- (NSString *)windowNibName
{
  return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  return [NSKeyedArchiver archivedDataWithRootObject:appliedEffects];
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError
{
  LayerEffect *effect =
      (LayerEffect *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  [self setAppliedEffects:effect];
  return YES;
}

@synthesize keysArray;

- (NSArray*)keysArray {
  for (Effect *effect in [appliedEffects arrangedEffects]) {
    if ([effect isKindOfClass:[AppleScriptEffect class]]) {
      AppleScriptEffect *appleScriptEffect = (AppleScriptEffect *)effect;
      return [appleScriptEffect keys];
    }
  }
  
  return [NSArray array];
}

- (NSData *)writeEffect:(Effect *)effect toPasteboard:(NSPasteboard *)pb {
  [pb declareTypes:[NSArray arrayWithObject:EffectPasteboardType] owner:self];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:effect];
  [pb setData:data forType:EffectPasteboardType];
  return data;
}

- (Effect *)readEffectFromPasteboard:(NSPasteboard *)pb {
  NSArray *types = [pb types];
  if ([types containsObject:EffectPasteboardType]) {
    NSData *data = [pb dataForType:EffectPasteboardType];
    return (Effect *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  return nil;
}

- (IBAction)cut:(id)sender {
  Effect *effect = [self selectedEffect];
      
  if (effect) {
    NSUInteger index = [appliedEffectsController selectionIndex];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [self writeEffect:effect toPasteboard:pb];
    NSString *actionName = [NSString stringWithFormat:@"Cut %@", [effect name]];
    [appliedEffectsController removeObjectAtArrangedObjectIndex:index
                                                 withActionName:actionName];
  } else {
    NSBeep();
  }
}

- (IBAction)copy:(id)sender {
  Effect *effect = [self selectedEffect];
  
  if (effect) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [self writeEffect:effect toPasteboard:pb];
  } else {
    NSBeep();
  }
}

- (IBAction)paste:(id)sender {
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  Effect *effect = [self readEffectFromPasteboard:pb];
  if (effect) {
    NSUInteger index = [appliedEffectsController selectionIndex];
    if (index == NSNotFound) {
      index = [[appliedEffectsController arrangedObjects] count];
    } else {
      index++;  // insert after the selection
    }
    NSString *actionName =
        [NSString stringWithFormat:@"Paste %@", [effect name]];
    [appliedEffectsController insertObject:effect
                     atArrangedObjectIndex:index
                            withActionName:actionName];
  } else {
    NSBeep();
  }
}

- (void)startObservingEffect:(Effect *)effect {
  [effect addObserver:self
           forKeyPath:@"visible"
              options:(NSKeyValueObservingOptionNew
                       | NSKeyValueObservingOptionOld)
              context:nil];
  
  NSDictionary *observedKeys = [[effect class] undoProperties];
  
  for (NSString *key in [observedKeys keyEnumerator]) {
    [effect addObserver:self
             forKeyPath:key
                options:(NSKeyValueObservingOptionNew
                         | NSKeyValueObservingOptionOld)
                context:[observedKeys objectForKey:key]];
  }
}

- (void)stopObservingEffect:(Effect *)effect {
  [effect removeObserver:self forKeyPath:@"visible"];
  NSDictionary *observedKeys = [[effect class] undoProperties];
  for (NSString *key in [observedKeys keyEnumerator]) {
    [effect removeObserver:self forKeyPath:key];
  }
}

@end
