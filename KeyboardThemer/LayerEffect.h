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

// An effect that composites other effects in layers. This effect isn't
// available in the effects list, but it is what composites all of the applied
// effects.

#import <Cocoa/Cocoa.h>

#import "Effect.h"


@interface LayerEffect : Effect {
  NSMutableArray *arrangedEffects;
}

@property (readonly) NSMutableArray *arrangedEffects;

+ (NSDictionary *)undoProperties;

@end
