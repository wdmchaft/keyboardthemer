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

// The keyboard theme document: arranged effects and their settings.

#import <Cocoa/Cocoa.h>

#import "DraggableEffectArrayController.h"
#import "LayerEffect.h"


@interface MyDocument : NSDocument
{
  LayerEffect *appliedEffects;
  NSArray *availableEffects;
  IBOutlet DraggableEffectArrayController *appliedEffectsController;
  IBOutlet NSObjectController *keyboardManagerController;
  IBOutlet NSTableView *appliedEffectsView;
  IBOutlet NSBox *settingsBox;
}

@property (retain) LayerEffect* appliedEffects;
@property (readonly) NSArray* availableEffects;
@property (readonly) NSArray* keysArray;

- (void)startObservingEffect:(Effect*)effect;
- (void)stopObservingEffect:(Effect*)effect;

@end
