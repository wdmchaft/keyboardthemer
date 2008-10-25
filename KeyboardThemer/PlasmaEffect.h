/*
 * Copyright 2009 Dominic Cooney.
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

// Implements a swirling plasma effect. See:
// http://en.wikipedia.org/wiki/Plasma_effect
// http://student.kuleuven.be/~m0216922/CG/plasma.html

#import <Cocoa/Cocoa.h>

#import "Effect.h"


@interface PlasmaComponent : NSObject <NSCoding> {
  CGFloat frequency;
  CGFloat offset;
  CGFloat power;
}

@property CGFloat frequency;
@property CGFloat offset;
@property CGFloat power;

@end

@interface PlasmaEffect : Effect {
  PlasmaComponent *red;
  PlasmaComponent *green;
  PlasmaComponent *blue;
  PlasmaComponent *alpha;
  CGFloat speed;
  CGFloat t;
}

@property (readonly, retain) PlasmaComponent *red;
@property (readonly, retain) PlasmaComponent *green;
@property (readonly, retain) PlasmaComponent *blue;
@property (readonly, retain) PlasmaComponent *alpha;
@property CGFloat speed;

+ (NSDictionary *)undoProperties;

@end


@interface PlasmaSettingsViewController : EffectSettingsViewController {
  
}

@end