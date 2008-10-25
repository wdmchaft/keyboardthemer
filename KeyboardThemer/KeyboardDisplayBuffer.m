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

#import "KeyboardDisplayBuffer.h"


void getPixel(CGFloat *bitmap, int x, int y,
              CGFloat *r, CGFloat *g, CGFloat *b, CGFloat *a) {
  const int width = 18;
  *r = bitmap[4 * (y * width + x)];
  *g = bitmap[4 * (y * width + x) + 1];
  *b = bitmap[4 * (y * width + x) + 2];
  *a = bitmap[4 * (y * width + x) + 3];
}

typedef struct {
  Key from;
  Key to;
  int startX;
  int y;
} Run;

typedef struct {
  Key key;
  int x;
  int y;
  float amount;
} Blend;

Run runs[] = {
  { kKeyTilde, kKeyBackspace, 1, 0 },
  { kKeyTab, kKeyBackslash, 1, 1 },
  { kKeyA, kKeySingleQuote, 2, 2 },
  { kKeyZ, kKeyForwardSlash, 2, 3 }
};

Blend blends[] = {
  { kKeyCapsLock, 0, 2, 0.3 },
  { kKeyCapsLock, 1, 2, 0.7 },
  { kKeyLeftShift, 0, 3, 0.5 },
  { kKeyLeftShift, 1, 3, 0.5 },
  { kKeyLeftCtrl, 0, 4, 1.0 },
  { kKeyLeftVendor, 1, 4, 1.0 },
  { kKeyLeftAlt, 2, 4, 1.0 },
  { kKeyEnter, 13, 2, 0.5 },
  { kKeyEnter, 14, 2, 0.5 },
  { kKeyRightShift, 12, 3, 0.4 },
  { kKeyRightShift, 13, 3, 0.4 },
  { kKeyRightShift, 14, 3, 0.2 },
  { kKeyRightAlt, 9, 4, 0.2 },
  { kKeyRightAlt, 10, 4, 0.5 },
  { kKeyRightVendor, 10, 4, 0.5 },
  { kKeyRightVendor, 11, 4, 0.5 },
  { kKeyRightMenu, 12, 4, 1.0 },
  { kKeyRightCtrl, 13, 4, 1.0 },
  { kKeyDelete, 15, 0, 0.5 },
  { kKeyDelete, 15, 1, 0.5 },
  { kKeyHome, 16, 0, 1.0 },
  { kKeyPgUp, 17, 0, 1.0 },
  { kKeyEnd, 16, 1, 1.0 },
  { kKeyPgDn, 17, 1, 1.0 },
  { kKeyLeft, 15, 4, 1.0 },
  { kKeyUp, 16, 3, 1.0 },
  { kKeyDown, 16, 4, 1.0 },
  { kKeyRight, 17, 4, 1.0 },
};


@implementation KeyboardDisplayBuffer

- (id)init {
  self = [super init];
  if (self) {
    buffer = calloc(kNumKeys, sizeof(CGFloat) * 4);
  }
  return self;
}

- (void)dealloc {
  free(buffer);
  [super dealloc];
}

- (void)clear {
  memset(buffer, 0, kNumKeys * sizeof(CGFloat) * 4);
}

- (void)clearR:(CGFloat)r g:(CGFloat)g b:(CGFloat)b a:(CGFloat)a {
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    [self setColorComponentsForKey:key r:r g:g b:b a:a];
  }
}

- (void)colorComponentsForKey:(Key)key r:(CGFloat*)r g:(CGFloat*)g
                            b:(CGFloat*)b a:(CGFloat*)a {
  *r = buffer[key * 4];
  *g = buffer[key * 4 + 1];
  *b = buffer[key * 4 + 2];
  *a = buffer[key * 4 + 3];
}

- (void)setColorComponentsForKey:(Key)key r:(CGFloat)r g:(CGFloat)g b:(CGFloat)b
                               a:(CGFloat)a {
  buffer[key * 4] = r;
  buffer[key * 4 + 1] = g;
  buffer[key * 4 + 2] = b;
  buffer[key * 4 + 3] = a;
}

- (void)setKey:(Key)key color:(CGColorRef)color {
  CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
  if (kCGColorSpaceModelRGB != CGColorSpaceGetModel(colorSpace)) {
    @throw @"only RGB color spaces supported";
  }
  const CGFloat *components = CGColorGetComponents(color);
  memcpy((void *)&buffer[key * 4], (const void *)components, sizeof(CGFloat) * 4);
}

- (void)paintKey:(Key)key color:(CGColorRef)color {
  CGColorSpaceRef colorSpace = CGColorGetColorSpace(color);
  if (kCGColorSpaceModelRGB != CGColorSpaceGetModel(colorSpace)) {
    @throw @"only RGB color spaces supported";
  }
  const CGFloat *components = CGColorGetComponents(color);
  [self paintKey:(Key)key r:components[0] g:components[1] b:components[2]
               a:components[3]];
}

- (void)paintKey:(Key)key r:(CGFloat)r2 g:(CGFloat)g2 b:(CGFloat)b2
               a:(CGFloat)a2 {
  CGFloat r1, g1, b1, a1;
  [self colorComponentsForKey:key r:&r1 g:&g1 b:&b1 a:&a1];
  [self setColorComponentsForKey:key
                               r:r2 * a2 + r1 * (1.0f - a2)
                               g:g2 * a2 + g1 * (1.0f - a2)
                               b:b2 * a2 + b1 * (1.0f - a2)
                               a:MIN(1.0f, a2 + a1)];  
}

- (void)paintBuffer:(KeyboardDisplayBuffer *)theBuffer {
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    CGFloat r, g, b, a;    
    [theBuffer colorComponentsForKey:key r:&r g:&g b:&b a:&a];
    [self paintKey:key r:r g:g b:b a:a];
  }
}

- (void)paintBitmap:(CGFloat *)bitmap {
  Key key;
  int i, x;
  CGFloat r, g, b, a;
  
  // runs
  for (int i = 0; i < sizeof(runs) / sizeof(Run); i++) {
    Run *run = &runs[i];
    for (x = run->startX, key = run->from; key <= run->to; x++, key++) {
      getPixel(bitmap, x, run->y, &r, &g, &b, &a);
      [self paintKey:key r:r g:g b:b a:a];
    }
  }
  
  // blends
  for (i = 0; i < sizeof(blends) / sizeof(Blend); i++) {
    Blend *blend = &blends[i];
    getPixel(bitmap, blend->x, blend->y, &r, &g, &b, &a);
    [self paintKey:blend->key r:r g:g b:b a:blend->amount * a];
  }
}

@end
