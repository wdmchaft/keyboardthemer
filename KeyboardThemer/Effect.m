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

#import "Effect.h"


CGColorRef CGColorCreateFromNSColor(NSColor *color) {
  NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
  return CGColorCreateGenericRGB(
                                 [deviceColor redComponent],
                                 [deviceColor greenComponent],
                                 [deviceColor blueComponent],
                                 [deviceColor alphaComponent]);
}


@implementation Effect

+ (NSString *)pasteboardType {
  return @"MacLEDKeyboardLuxeedEffectV1";
}

- (id)init {
  self = [super init];
  if (self) {
    visible = YES;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self) {
    [self setName:(NSString *)[coder decodeObjectForKey:@"name"]];
    [self setVisible:[coder decodeBoolForKey:@"visible"]];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:name forKey:@"name"];
  [coder encodeBool:visible forKey:@"visible"];
}

@synthesize name;
@synthesize visible;

- (void)draw:(KeyboardDisplayBuffer *)buffer
      keyMap:(KeyMap*)keyMap
      events:(NSArray *)events {
  NSLog(@"draw:keyMap:events: not implemented");
}

- (NSViewController *)createViewController {
  NSLog(@"createViewController not implemented");
  return nil;
}

@end


@implementation EffectSettingsViewController

@synthesize effect;

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
  return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void) dealloc {
  [effect release];
  [super dealloc];
}

@end


@implementation NoSettingsViewController

- (id) init {
  return [super initWithNibName:@"NoSettings" bundle:nil];
}

@end