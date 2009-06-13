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

// Pushes key color data to the Luxeed deTA100 keyboard.

#import <Cocoa/Cocoa.h>
#include <IOKit/usb/IOUSBLib.h>
#include <mach/mach_types.h>

#import "Effect.h"
#import "KeyMap.h"

@interface Keyboard : NSObject {
  Effect *effect;
@private
  IOUSBInterfaceInterface **interface;
  CFRunLoopSourceRef keyDownSource;
  CFMachPortRef keyDownTap; 
  CFRunLoopSourceRef keyUpSource;
  CFMachPortRef keyUpTap;
  CFRunLoopSourceRef keyFlagsSource;
  CFMachPortRef keyFlagsTap; 
  CFRunLoopTimerRef packetTimer;
  CFRunLoopTimerContext *packetTimerContext;
  CFRunLoopRef runLoop;
  void *sendStatus;
  UInt8 buffer[6 * 0x41];
  UInt8 colorData[0x41 - 0x38 + 4 * 0x40];
  NSThread *animationThread;
  semaphore_t animationSemaphore;
  KeyMap *keyMap;
  KeyboardDisplayBuffer *kbdb;
  NSMutableArray *renderEvents;
  volatile NSMutableArray *pendingEvents;
}

@property (retain) Effect* effect;
@property (readonly) BOOL eventTapInstalled;

- (id)initWithInterface:(IOUSBInterfaceInterface **)ledInterface;
- (void)draw:(const UInt8 *)colors;
- (BOOL)wasDeviceRemoved;
- (void)shutdown;

@end
