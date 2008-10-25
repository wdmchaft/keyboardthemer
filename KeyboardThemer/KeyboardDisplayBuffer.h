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

// An RGBA bitmap of all of the keys on the keyboard which can be illuminated.
// The keys are logically indexed, however the clear methods can paint all of
// the keys and the paintBitmap method renders a rectangular 18 by 5 pixel
// bitmap onto the key bitmap.

#include <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>

#import "Key.h"


@interface KeyboardDisplayBuffer : NSObject {
@private
  CGFloat *buffer;
}

- (void)clear;
- (void)clearR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;
- (void)setKey:(Key)key color:(CGColorRef)color;
- (void)setColorComponentsForKey:(Key)key r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b
                               a:(CGFloat)a;
- (void)paintKey:(Key)key color:(CGColorRef)color;
- (void)paintKey:(Key)key r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a;
- (void)paintBuffer:(KeyboardDisplayBuffer*)buffer;

/**
 * Paints a 18 by 5 RGBA pixel bitmap over the keys. Non-square keys are rough
 * averages of the pixels they overlap. 
 */
- (void)paintBitmap:(CGFloat *)bitmap;
- (void)colorComponentsForKey:(Key)key r:(CGFloat*)r g:(CGFloat*)g
                            b:(CGFloat*)b a:(CGFloat*)a;

@end
