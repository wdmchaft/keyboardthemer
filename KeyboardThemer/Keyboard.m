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

#import "Keyboard.h"

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSThread.h>
#include <IOKit/IOCFPlugIn.h>
#include <libkern/OSAtomic.h>
#include <mach/task.h>

#import "KeyEvent.h"


struct SendStatus {
  UInt8 colors[6 * 0x41];  // color data
  int i;  // index of packet to send
  BOOL ok;  // OK to send packet?
  struct SendStatus *next;  // thing to send next
};
typedef struct SendStatus SendStatus;


void SendKeyboardPacket(CFRunLoopTimerRef timer, void *info);
void SendKeyboardPacketDone(void *refCon, IOReturn result, void *arg0);
CGEventRef KeyDownEvent(CGEventTapProxy proxy, CGEventType type,
                        CGEventRef event, void *refcon);
CGEventRef KeyUpEvent(CGEventTapProxy proxy, CGEventType type,
                      CGEventRef event, void *refcon);
CGEventRef KeyFlagsEvent(CGEventTapProxy proxy, CGEventType type,
                         CGEventRef event, void *refcon);


static const int messageSize = 6 * 0x41;
static const int numPackets = 6;
static const int packetSize = 0x41;
static const int checksumOffset = 5 * 0x41 + 0x0f;

// setup data which initializes and clears the keyboard
static const UInt8 setupData[] = {
  0x02, 0x02, 0x01, 0x80, 0x00, 0x01, 0x01, 0x00,
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00,

  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00,

  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00,

  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00,

  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00,

  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xb0,
  0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00
};

static const UInt8 header[] = {
  0x02, 0x02, 0x01, 0x80, 0x00, 0x00, 0x16, 0x00,
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
  0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

#define leadingPayloadSize (0x41 - 0x38)
#define packetPayloadSize 0x40
#define colorDataSize (leadingPayloadSize + 4 * packetPayloadSize)

static const UInt8 footer[] = {
  0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc4,
  0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00
};


@interface Keyboard (Private)

- (void)keyDown:(CGEventRef)event;
- (void)keyUp:(CGEventRef)event;
- (void)keyFlagsChanged:(CGEventRef)event;
- (UInt8)checksum:(UInt8 *)message;
- (void)formatMessage:(UInt8 *)message withColors:(UInt8 *)colors;
- (void)sendKeyboardPacket;
- (void)finishedSendingKeyboardPacketWithResult:(IOReturn)result;
- (void)animationThreadStart;
- (void)animate;

@end


@implementation Keyboard (Private)

- (void)animationThreadStart {
  NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
  NSLog(@"starting animation thread");
  
  // initialize the keyboard
  [self draw:setupData];
  
  while (YES) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[NSRunLoop currentRunLoop] run];
    [pool release];
  }
  NSLog(@"stopping animation thread");
  [outerPool release];
}

- (void)animate {
  UInt8 colorBuffer[colorDataSize];
  memset(colorBuffer, 0, sizeof(colorBuffer));
  
  [kbdb clearR:0.0f g:0.0f b:0.0f a:1.0f];
  
  // call the effect to generate the frame
  if (effect) {
    [effect draw:kbdb keyMap:keyMap events:renderEvents];
  }
  
  // convert the floating-point representation into RGB888
  for (Key key = kMinKey; key <= kMaxKey; key++) {
    CGFloat r, g, b, a;
    [kbdb colorComponentsForKey:(Key)key r:&r g:&g b:&b a:&a];
    int i = [keyMap offsetForKey:(Key)key];
    colorBuffer[i] = (UInt8)(0xff * r * a);
    colorBuffer[i + 1] = (UInt8)(0xff * g * a);
    colorBuffer[i + 2] = (UInt8)(0xff * b * a);
  }
  UInt8 *message = (UInt8 *)malloc(messageSize);
  [self formatMessage:message withColors:colorBuffer];
  [self draw:message];
  free(message);

  // empty the render events collection; that is going to become the pending
  // event queue soon
  [renderEvents removeAllObjects];
  
  NSMutableArray *oldPendingEvents;
  do {
    oldPendingEvents = (NSMutableArray *)pendingEvents;
  } while (!OSAtomicCompareAndSwapPtrBarrier(oldPendingEvents, renderEvents,
                                             (void * volatile *)&pendingEvents));
  renderEvents = oldPendingEvents;
}

- (void)keyFlagsChanged:(CGEventRef)event {
  // key codes for keys that produce flag change but not key down/up events
  static const int kRightVendorCode = 0x36;
  static const int kLeftVendorCode = 0x37;
  static const int kLeftShiftCode = 0x38;
  static const int kCapsLockCode = 0x39;
  static const int kLeftAltCode = 0x3a;
  static const int kLeftCtrlCode = 0x3b;
  static const int kRightShiftCode = 0x3c;
  static const int kRightAltCode = 0x3d;
  static const int kRightCtrlCode = 0x3e;

  // flag modifiers for the 'pressed' state of modifier keys
  static const CGEventFlags kRightVendorDown = 0x00010;
  static const CGEventFlags kLeftVendorDown = 0x00008;
  static const CGEventFlags kLeftShiftDown = 0x00002;
  static const CGEventFlags kCapsLockOn = 0x10000;
  static const CGEventFlags kLeftAltDown = 0x00020;
  static const CGEventFlags kLeftCtrlDown = 0x00001;
  static const CGEventFlags kRightShiftDown = 0x00004;
  static const CGEventFlags kRightAltDown = 0x00040;
  static const CGEventFlags kRightCtrlDown = 0x02000;

  CGEventFlags flags = CGEventGetFlags(event);
  NSLog(@"flags: %08x", flags);
  int keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

  if ((keyCode == kRightVendorCode && flags & kRightVendorDown)
      || (keyCode == kLeftVendorCode && flags & kLeftVendorDown)
      || (keyCode == kLeftShiftCode && flags & kLeftShiftDown)
      || (keyCode == kCapsLockCode && flags & kCapsLockOn)
      || (keyCode == kLeftAltCode && flags & kLeftAltDown)
      || (keyCode == kLeftCtrlCode && flags & kLeftCtrlDown)
      || (keyCode == kRightShiftCode && flags & kRightShiftDown)
      || (keyCode == kRightAltCode && flags & kRightAltDown)
      || (keyCode == kRightCtrlCode && flags & kRightCtrlDown)) {
    [self keyDown:event];
  } else {
    [self keyUp:event];
  }
}

- (void)keyDown:(CGEventRef)event {
  UniCharCount actualStringLength;
  UniChar unicodeString[8];
  
  CGEventKeyboardGetUnicodeString(event, 7, &actualStringLength, unicodeString);
  unicodeString[actualStringLength] = 0;
  NSLog(@"Key: %s (0x%02x; repeat %d; keyboard %d) down", unicodeString,
        CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode),
        CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat),
        CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType));

  int keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
  int repeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
  Key key;
  if (!repeat && [keyMap keyForScanCode:keyCode key:&key]) {
    KeyEvent *keyEvent = [[KeyEvent alloc] initWithKey:key isDown:YES];
    [pendingEvents addObject:keyEvent];
  }
}

- (void) keyUp:(CGEventRef)event {
  UniCharCount actualStringLength;
  UniChar unicodeString[8];
  
  CGEventKeyboardGetUnicodeString(event, 7, &actualStringLength, unicodeString);
  unicodeString[actualStringLength] = 0;
  NSLog(@"Key: %s (0x%02x; keyboard %d) up", unicodeString,
        CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode),
        CGEventGetIntegerValueField(event, kCGKeyboardEventKeyboardType));
  
  int keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
  Key key;
  if ([keyMap keyForScanCode:keyCode key:&key]) {    
    KeyEvent *keyEvent = [[KeyEvent alloc] initWithKey:key isDown:NO];
    [pendingEvents addObject:keyEvent];
  }
}

// computes the checksum of the specified six-packet message
- (UInt8)checksum:(UInt8 *)message {
  UInt8 checksum = -0x0e;
  
  for (int i = 0; i < checksumOffset; i++) {
    checksum += message[i];
  }
  
  return checksum;
}

// copies the contiguous array of color data into the packetized format
- (void)formatMessage:(UInt8 *)message withColors:(UInt8 *)colors {
  memcpy(message, header, sizeof(header));
  size_t offset = sizeof(header);
  
  // copy the first partial packet
  memcpy(&message[offset], colors, leadingPayloadSize);
  offset += leadingPayloadSize;
  
  // copy the full packets
  for (int i = 0; i < 5; i++) {
    message[offset++] = 0x02;
    memcpy(&message[offset],
           &colors[leadingPayloadSize + i * packetPayloadSize],
           packetPayloadSize);
    offset += packetPayloadSize;
  }
  
  // copy the footer and update the checksum
  memcpy(&message[5 * packetSize], footer, sizeof(footer));
  message[checksumOffset] = [self checksum:message];
}

- (void)sendKeyboardPacket {
  IOReturn kr;
  
  if (!sendStatus || !((SendStatus *)sendStatus)->ok) {
    // nothing to send; or busy writing to the pipe
    return;
  }
  
  ((SendStatus *)sendStatus)->ok = NO;  // sending!

  /*
  fprintf(stderr, "\n\n**** %d ****\n", ((SendStatus *)sendStatus)->i);
  UInt8 *start = &((SendStatus *)sendStatus)->colors[((SendStatus *)sendStatus)->i * packetSize];
  for (int i = 0; i < packetSize; i++, start++) {
    fprintf(stderr, "%02x%s", *start, (i % 0x10) == 0x0f ? "\n" : " ");
  }
  */
  
  kr = (*interface)->WritePipeAsync(interface,
                                    1,
                                    &((SendStatus *)sendStatus)->colors[((SendStatus *)sendStatus)->i * packetSize],
                                    packetSize,
                                    SendKeyboardPacketDone,
                                    self);
  
  if (kr) {
    NSLog(@"couldn't write packet %d (%08x)", ((SendStatus *)sendStatus)->i, kr);
  }
}

- (void)finishedSendingKeyboardPacketWithResult:(IOReturn)result {
  if (result) {
    NSLog(@"didn't write packet %d (%08x)", ((SendStatus *)sendStatus)->i, result);
  }
  
  ((SendStatus *)sendStatus)->ok = YES;
  ((SendStatus *)sendStatus)->i++;

  // shuffle up to the next packet, if the last transfer is done
  if (((SendStatus *)sendStatus)->i >= numPackets) {
    @synchronized (self) {
      SendStatus *next = ((SendStatus *)sendStatus)->next;
      free(sendStatus);
      sendStatus = (void *)next;
    }
    
    if (sendStatus == NULL || ((SendStatus *)sendStatus)->next == NULL) {
      [self performSelector:@selector(animate)
                   onThread:animationThread
                 withObject:nil
              waitUntilDone:NO];
      // TODO: should throttle the rate
    }
  }
}

@end

@implementation Keyboard

- (id)initWithInterface:(IOUSBInterfaceInterface **)ledInterface {
  if (![super init]) {
    return nil;
  }
  
  interface = ledInterface;
  (*interface)->AddRef(interface);
  
  // save a reference to the run loop, for removing events later
  runLoop = CFRunLoopGetCurrent();
  CFRetain(runLoop);
  
  // set up event taps to listen to key events
  
  keyDownTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                                kCGEventTapOptionListenOnly,
                                CGEventMaskBit(kCGEventKeyDown),
                                KeyDownEvent, self);
  if (!keyDownTap) {
    NSLog(@"couldn't create key down event tap");
  }
  
  keyDownSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                keyDownTap, 0);
  CFRunLoopAddSource(runLoop, keyDownSource, kCFRunLoopCommonModes);
  
  keyUpTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                              kCGEventTapOptionListenOnly,
                              CGEventMaskBit(kCGEventKeyUp),
                              KeyUpEvent, self);
  if (!keyUpTap) {
    NSLog(@"couldn't create key up event tap");
  }
  
  keyUpSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, keyUpTap, 0);
  CFRunLoopAddSource(runLoop, keyUpSource, kCFRunLoopCommonModes);
  
  keyFlagsTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                                 kCGEventTapOptionListenOnly,
                                 CGEventMaskBit(kCGEventFlagsChanged),
                                 KeyFlagsEvent, self);
  if (!keyFlagsTap) {
    NSLog(@"couldn't create key down event tap");
  }
  
  keyFlagsSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
                                                 keyFlagsTap, 0);
  CFRunLoopAddSource(runLoop, keyFlagsSource, kCFRunLoopCommonModes);
  
  // nothing to send yet
  sendStatus = NULL;
  
  // set up a timer to send individual packets to the device; this refresh rate
  // corresponds to about six frames per second and seems to not drop
  // keystrokes; if you're not typing the keyboard can animate at about 40 FPS
  // without corruption
  packetTimerContext =
      (CFRunLoopTimerContext *)malloc(sizeof(CFRunLoopTimerContext));
  packetTimerContext->version = 0;
  packetTimerContext->info = (void *)self;
  packetTimerContext->retain = NULL;
  packetTimerContext->release = NULL;
  packetTimerContext->copyDescription = NULL;
  packetTimer = CFRunLoopTimerCreate(kCFAllocatorDefault,
                                     CFAbsoluteTimeGetCurrent() + 1.0,
                                     30000.0 / 1000000.0,
                                     0, 0, SendKeyboardPacket,
                                     packetTimerContext);
  CFRunLoopAddTimer(runLoop, packetTimer, kCFRunLoopCommonModes);

  keyMap = [[KeyMap alloc] init];
  pendingEvents = [[NSMutableArray arrayWithCapacity:1] retain];
  renderEvents = [[NSMutableArray arrayWithCapacity:1] retain];
  kbdb = [[KeyboardDisplayBuffer alloc] init];  
  
  // start a background thread for drawing frames
  animationThread = [[NSThread alloc] initWithTarget:self
                                            selector:@selector(animationThreadStart)
                                              object:nil];
  [animationThread start];

  return self;
}

@synthesize effect;

- (BOOL)wasDeviceRemoved {
  // see if this device was closed
  
  IOReturn ior = (*interface)->GetPipeStatus(interface, 1);

  // sometimes there's an intervening pipe stall from a write that failed when
  // the device was unplugged that we have to clear to get the underlying status
  if (ior == kIOUSBPipeStalled) {
    ior = (*interface)->ClearPipeStall(interface, 1);
  }
  
  return ior == kIOReturnNoDevice;
}

- (void)shutdown {
  // stop the animation thread

  [animationThread release];
  animationThread = NULL;
  
  // shut down the animation loop

  CFRunLoopRemoveTimer(runLoop, packetTimer, kCFRunLoopCommonModes);
  CFRelease(packetTimer);
  packetTimer = NULL;
  free(packetTimerContext);
  packetTimerContext = NULL;
  
  // shut down the event taps

  CFRunLoopRemoveSource(runLoop, keyDownSource, kCFRunLoopCommonModes);
  CFRelease(keyDownSource);
  keyDownSource = NULL;
  CFRelease(keyDownTap);
  keyDownTap = NULL;
  
  CFRunLoopRemoveSource(runLoop, keyUpSource, kCFRunLoopCommonModes);
  CFRelease(keyUpSource);
  keyUpSource = NULL;
  CFRelease(keyUpTap);
  keyUpTap = NULL;

  CFRunLoopRemoveSource(runLoop, keyFlagsSource, kCFRunLoopCommonModes);
  CFRelease(keyFlagsSource);
  keyFlagsSource = NULL;
  CFRelease(keyFlagsTap);
  keyFlagsTap = NULL;
  
  CFRelease(runLoop);
  runLoop = NULL;
  
  // TODO: tear down buffered data
  
  // shut down the USB interface

  (*interface)->USBInterfaceClose(interface);
  (*interface)->Release(interface);
  interface = NULL;
}

- (void)draw:(const UInt8 *)colors {
  SendStatus *request = (SendStatus *)malloc(sizeof(SendStatus));
  
  // save a copy of the data to send
  memcpy(request->colors, colors, sizeof(request->colors));
  
  // set up a transfer
  request->i = 0;
  request->ok = YES;
  request->next = NULL;
  
  // add the request to the end of the chain
  @synchronized(self) {
    SendStatus **link = (SendStatus **)&sendStatus;
    while (*link != NULL) {
      link = &(*link)->next;
    }
    *link = request;
  }
}

@end


CGEventRef KeyDownEvent(CGEventTapProxy proxy, CGEventType type,
                        CGEventRef event, void *refcon) {
  [(Keyboard *)refcon keyDown:event];
  return event;
}


CGEventRef KeyUpEvent(CGEventTapProxy proxy, CGEventType type,
                      CGEventRef event, void *refcon) {
  [(Keyboard *)refcon keyUp:event];
  return event;
}


CGEventRef KeyFlagsEvent(CGEventTapProxy proxy, CGEventType type,
                         CGEventRef event, void *refcon) {
  [(Keyboard *)refcon keyFlagsChanged:event];
  return event;
}


void SendKeyboardPacketDone(void *refCon, IOReturn result, void *arg0) {
  [(Keyboard *)refCon finishedSendingKeyboardPacketWithResult:result];
}


void SendKeyboardPacket(CFRunLoopTimerRef timer, void *info) {
  [(Keyboard *)info sendKeyboardPacket];
}
