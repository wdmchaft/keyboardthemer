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

#import "PlasmaEffect.h"

// adapted from http://mrl.nyu.edu/~perlin/noise/

int p[] = {
  151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140,
  36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234,
  75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237,
  149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48,
  27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105,
  92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73,
  209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86,
  164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38,
  147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189,
  28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153,
  101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224,
  232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144,
  12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214,
  31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150,
  254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66,
  215, 61, 156, 180, 151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194,
  233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6,
  148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
  57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74,
  165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60,
  211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25,
  63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135,
  130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
  250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59,
  227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2,
  44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19,
  98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251,
  34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249,
  14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115,
  121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72,
  243, 141, 128, 195, 78, 66, 215, 61, 156, 180
};

double fade(double t) {
  return t * t * t * (t * (t * 6 - 15) + 10);
}

double lerp(double t, double a, double b) {
  return a + t * (b - a);
}

double grad(int hash, double x, double y, double z) {
  int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
  double u = h < 8 ? x : y;               // INTO 12 GRADIENT DIRECTIONS.
  double v = h<4 ? y : h == 12 || h == 14 ? x : z;
  return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

double noise(double x, double y, double z) {
  int X = (int)floor(x) & 255,                  // FIND UNIT CUBE THAT
  Y = (int)floor(y) & 255,                      // CONTAINS POINT.
  Z = (int)floor(z) & 255;
  x -= floor(x);                                // FIND RELATIVE X,Y,Z
  y -= floor(y);                                // OF POINT IN CUBE.
  z -= floor(z);
  double u = fade(x),                           // COMPUTE FADE CURVES
  v = fade(y),                                  // FOR EACH OF X,Y,Z.
  w = fade(z);
  int A = p[X  ]+Y, AA = p[A]+Z, AB = p[A+1]+Z, // HASH COORDINATES OF
  B = p[X+1]+Y, BA = p[B]+Z, BB = p[B+1]+Z;     // THE 8 CUBE CORNERS,
  
  return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ),  // AND ADD
                                 grad(p[BA  ], x-1, y  , z   )), // BLENDED
                         lerp(u, grad(p[AB  ], x  , y-1, z   ),  // RESULTS
                                 grad(p[BB  ], x-1, y-1, z   ))),// FROM  8
                 lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),  // CORNERS
                                 grad(p[BA+1], x-1, y  , z-1 )), // OF CUBE
                         lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
                                 grad(p[BB+1], x-1, y-1, z-1 ))));
}


@implementation PlasmaComponent

@synthesize frequency;
@synthesize offset;
@synthesize power;

- (id)init {
  self = [super init];
  if (self) {
    frequency = 3.0f;
    offset = 0.0f;
    power = 1.0f;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    frequency = [coder decodeFloatForKey:@"frequency"];
    offset = [coder decodeFloatForKey:@"offset"];
    power = [coder decodeFloatForKey:@"power"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeFloat:frequency forKey:@"frequency"];
  [coder encodeFloat:offset forKey:@"offset"];
  [coder encodeFloat:power forKey:@"power"];
}

@end


@implementation PlasmaEffect

+ (NSDictionary *)undoProperties {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          @"Red Frequency", @"red.frequency",
          @"Red Power", @"red.power",
          @"Red Offset", @"red.offset",
          @"Green Frequency", @"green.frequency",
          @"Green Power", @"green.power",
          @"Green Offset", @"green.offset",
          @"Blue Frequency", @"blue.frequency",
          @"Blue Power", @"blue.power",
          @"Blue Offset", @"blue.offset",
          @"Alpha Frequency", @"alpha.frequency",
          @"Alpha Power", @"alpha.power",
          @"Alpha Offset", @"alpha.offset",
          @"Speed", @"speed",
          nil];
}

@synthesize red;
@synthesize green;
@synthesize blue;
@synthesize alpha;
@synthesize speed;

- (id)init {
  self = [super init];
  if (self) {
    [self setName:@"Plasma"];
    red = [[PlasmaComponent alloc] init];
    green = [[PlasmaComponent alloc] init];
    [green setOffset:2.0f * M_PI / 3.0f];
    blue = [[PlasmaComponent alloc] init];
    [blue setOffset:4.0f * M_PI / 3.0f];
    alpha = [[PlasmaComponent alloc] init];
    speed = 0.001f;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    red = [[coder decodeObjectForKey:@"red"] retain];
    green = [[coder decodeObjectForKey:@"green"] retain];
    blue = [[coder decodeObjectForKey:@"blue"] retain];
    alpha = [[coder decodeObjectForKey:@"alpha"] retain];
    speed = [coder decodeFloatForKey:@"speed"];
  }
  return self;
}

- (void)dealloc {
  [red release];
  [green release];
  [blue release];
  [alpha release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeObject:red forKey:@"red"];
  [coder encodeObject:green forKey:@"green"];
  [coder encodeObject:blue forKey:@"blue"];
  [coder encodeObject:alpha forKey:@"alpha"];
  [coder encodeFloat:speed forKey:@"speed"];
}

- (NSViewController *)createViewController {
  EffectSettingsViewController *viewController =
      [[PlasmaSettingsViewController alloc] init];
  [viewController setEffect:self];
  return viewController;
}

- (void)draw:(KeyboardDisplayBuffer *)displayBuffer
      keyMap:(KeyMap *)keyMap
      events:(NSArray *)events {
  CGFloat *buffer = (CGFloat *)calloc(4 * 18 * 5, sizeof(CGFloat));

  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 18; x++) {
      t += speed;
      CGFloat value = noise(x / 9.0f, y / 2.5f, t);
      buffer[4 * (y * 18 + x)] = red.power * pow(0.5f + 0.5f * cos(red.frequency * value + red.offset), 2.0f);
      buffer[4 * (y * 18 + x) + 1] = green.power * pow(0.5f + 0.5f * cos(green.frequency * value + green.offset), 2.0f);
      buffer[4 * (y * 18 + x) + 2] = blue.power * pow(0.5f + 0.5f * cos(blue.frequency * value + blue.offset), 2.0f);
      buffer[4 * (y * 18 + x) + 3] = alpha.power * pow(0.5f + 0.5f * cos(alpha.frequency * value + alpha.offset), 2.0f);
    }
  }

  [displayBuffer paintBitmap:buffer];
  free(buffer);
}

@end


@implementation PlasmaSettingsViewController

- (id)init {
  return [super initWithNibName:@"PlasmaSettings" bundle:nil];
}

@end
