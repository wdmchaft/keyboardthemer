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

#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>

#import "KeyboardManager.h"

// flag for when no keyboard is inserted as the "primary" keyboard
static const UInt32 NO_PRIMARY_KEYBOARD = (UInt32) NSNotAnIntegerMapKey;

extern kern_return_t mach_port_deallocate(ipc_space_t task,
                                          mach_port_name_t name);


void KeyboardDeviceAdded(void *context, io_iterator_t iterator);
void KeyboardDeviceRemoved(void *context, io_iterator_t iterator);


static KeyboardManager *sharedKeyboardManager = NULL;


@interface KeyboardManager (Private)
- (void)addKeyboard:(Keyboard *)keyboard at:(UInt32)location;
- (void)keyboardRemoved;
@end


@implementation KeyboardManager (Private)

- (void)addKeyboard:(Keyboard *)newKeyboard at:(UInt32)location {
  NSMapInsertKnownAbsent(keyboards, (void *)location, newKeyboard);
  
  if (keyboardLocation == NO_PRIMARY_KEYBOARD) {
    keyboardLocation = location;
    [self setKeyboard:newKeyboard];
  }
}

- (void)removeKeyboard:(Keyboard *)removedKeyboard at:(UInt32)location {
  [removedKeyboard shutdown];

  NSMapRemove(keyboards, (void *)location);
  
  if (location == keyboardLocation) {
    [self setKeyboard:nil];
  }
}

- (void)keyboardRemoved {
  NSMapEnumerator enumerator = NSEnumerateMapTable(keyboards);
  UInt32 key;
  Keyboard *value;
  while (NSNextMapEnumeratorPair(&enumerator, (void **) &key,
                                 (void **) &value)) {
    if ([value wasDeviceRemoved]) {
      [self removeKeyboard:value at:key];
    }
  }
  NSEndMapTableEnumeration(&enumerator);
}

@end

@implementation KeyboardManager

+ (KeyboardManager *)sharedInstance {
  if (!sharedKeyboardManager) {
    sharedKeyboardManager = [[KeyboardManager alloc] init];
  }
  return sharedKeyboardManager;
}

+ (void)releaseSharedInstance {
  if (sharedKeyboardManager) {
    [sharedKeyboardManager release];
    sharedKeyboardManager = NULL;
  }
}

@synthesize keyboard;

- (id)init {
  self = [super init];
  if (self) {
    keyboardLocation = NO_PRIMARY_KEYBOARD;
    keyboards = NSCreateMapTable(NSIntegerMapKeyCallBacks,
                                 NSObjectMapValueCallBacks,
                                 0);
  }
  return self;
}

- (void)dealloc {
  NSFreeMapTable(keyboards);
  [super dealloc];
}

- (IOReturn)start {
  const SInt32 kLuxeedVendorID = 0x534b;
  const SInt32 kLuxeedDeTA100ProductID = 0x0600;

  static io_iterator_t gKeyboardDeviceAddedIter;
  static io_iterator_t gKeyboardDeviceRemovedIter;
  static IONotificationPortRef gNotifyPort;
  
  mach_port_t masterPort;
  CFMutableDictionaryRef matchingDict;
  CFRunLoopSourceRef runLoopSource;
  kern_return_t kr;
  
  kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
  if (kr || !masterPort) {
    NSLog(@"couldn't create master I/O Kit port (%08x)", kr);
    return kr;
  }
  
  matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
  if (!matchingDict) {
    NSLog(@"couldn't create a USB matching dictionary");
    mach_port_deallocate(mach_task_self(), masterPort);
    return kIOReturnError;
  }
  
  CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID),
                       CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type,
                                      &kLuxeedVendorID));
  CFDictionarySetValue(matchingDict, CFSTR(kUSBProductID),
                       CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type,
                                      &kLuxeedDeTA100ProductID));
  
  // create a notification port and add its loop event source to the program's
  // run loop
  gNotifyPort = IONotificationPortCreate(masterPort);
  runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                     kCFRunLoopDefaultMode);
  CFRelease(runLoopSource);
  runLoopSource = NULL;
  
  // retain the matching dictionary one extra time; each call to IOServiceAdd-
  // MatchingNotification consumes one reference
  matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
  
  // set up two notifications; one when a device is added, one when a device is
  // removed
  
  kr = IOServiceAddMatchingNotification(gNotifyPort, kIOFirstMatchNotification,
                                        matchingDict, KeyboardDeviceAdded, 
                                        NULL, &gKeyboardDeviceAddedIter);
  
  KeyboardDeviceAdded(NULL, gKeyboardDeviceAddedIter);
  
  if (kr) {
    NSLog(@"couldn't add matching notification for device insertion (%08x)",
          kr);
    IONotificationPortDestroy(gNotifyPort);
    mach_port_deallocate(mach_task_self(), masterPort);
    return kr;
  }
  
  kr = IOServiceAddMatchingNotification(gNotifyPort, kIOTerminatedNotification, 
                                        matchingDict, KeyboardDeviceRemoved,
                                        NULL, &gKeyboardDeviceRemovedIter);
  
  KeyboardDeviceRemoved(NULL, gKeyboardDeviceRemovedIter);
  
  if (kr) {
    NSLog(@"couldn't add matching notification for device removal (%08x)", kr);
    
    IONotificationPortDestroy(gNotifyPort);
    mach_port_deallocate(mach_task_self(), masterPort);
    return kr;
  }
  
  mach_port_deallocate(mach_task_self(), masterPort);
  masterPort = 0;
  
  return kIOReturnSuccess;
}

- (IOReturn)stop {
  // TODO: destroy notification port; stop listening for devices

  return kIOReturnSuccess;
}

@end


IOReturn ConfigureDevice(IOUSBDeviceInterface **device) {
  UInt8 numConfig;
  IOReturn kr;
  IOUSBConfigurationDescriptorPtr configDesc;
  
  kr = (*device)->GetNumberOfConfigurations(device, &numConfig);
  if (kr) {
    NSLog(@"couldn't get configuration count (%08x)", kr);
    return kr;
  }
  
  NSLog(@"device has %d configurations", (int) numConfig);
  
  kr = (*device)->GetConfigurationDescriptorPtr(device, 0, &configDesc);
  if (kr) {
    NSLog(@"couldn't get configuration %d (%08x)", 0, kr);
    return kr;
  }
  
  kr = (*device)->SetConfiguration(device, configDesc->bConfigurationValue);
  if (kr) {
    NSLog(@"couldn't set configuration %d (%08x)", 0, kr);
    return kr;
  }
  
  return kIOReturnSuccess;
}

void PrintPipeProperties(IOUSBInterfaceInterface **interface, int pipeRef) {
  IOReturn kr;
  UInt8 direction;
  UInt8 number;
  UInt8 transferType;
  UInt16 maxPacketSize;
  UInt8 interval;
  char *message;
  
  kr = (*interface)->GetPipeProperties(interface, pipeRef, &direction, &number,
                                       &transferType, &maxPacketSize,
                                       &interval);
  
  if (kr) {
    NSLog(@"couldn't get the properties of pipe %d (%08x)", pipeRef, kr);
    return;
  }
  
  printf("PipeRef %d: ", pipeRef);
  
  switch (direction) {
    case kUSBOut:
      message = "out";
      break;
    case kUSBIn:
      message = "in";
      break;
    case kUSBNone:
      message = "none";
      break;
    case kUSBAnyDirn:
      message = "any";
      break;
    default:
      message = "???";
      break;
  }
  printf("direction %s, ", message);
  
  switch (transferType) {
    case kUSBControl:
      message = "control";
      break;
    case kUSBIsoc:
      message = "isoc";
      break;
    case kUSBBulk:
      message = "bulk";
      break;
    case kUSBInterrupt:
      message = "interrupt";
      break;
    case kUSBAnyType:
      message = "any";
      break;
    default:
      message = "???";
      break;
  }
  printf("transfer type %s, max packet size %d, interval %d\n", message,
         maxPacketSize, interval);
}

IOReturn FindInterfaces(IOUSBDeviceInterface **device) {
  IOReturn kr;
  HRESULT hr;
  IOUSBFindInterfaceRequest request;
  io_iterator_t iterator;
  io_service_t usbInterface;
  IOCFPlugInInterface **plugIn = NULL;
  IOUSBInterfaceInterface **interface = NULL;
  SInt32 score;
  UInt8 interfaceClass;
  UInt8 interfaceSubClass;
  UInt8 interfaceNumEndpoints;
  int pipeRef;
  
  // find all of the interfaces
  request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
  request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
  request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
  request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
  
  kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
  if (kr) {
    NSLog(@"couldn't create interface iterator (%08x)", kr);
    return kr;
  }
  
  while (usbInterface = IOIteratorNext(iterator)) {
    kr = IOCreatePlugInInterfaceForService(usbInterface,
                                           kIOUSBInterfaceUserClientTypeID,
                                           kIOCFPlugInInterfaceID,
                                           &plugIn, &score);
    IOObjectRelease(usbInterface);
    if (kr || !plugIn) {
      NSLog(@"couldn't create plug-in for interface (%08x)", kr);
      continue;
    }
    
    hr = (*plugIn)->QueryInterface(
                                   plugIn,
                                   CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                   (LPVOID *) &interface);
    
    (*plugIn)->Release(plugIn);
    
    if (hr || !interface) {
      NSLog(@"couldn't create interface for interface (%08x)", hr);
      continue;
    }
    
    kr = (*interface)->GetInterfaceClass(interface, &interfaceClass);
    if (kr) {
      NSLog(@"couldn't get interface class (%08x)", kr);
      (*interface)->Release(interface);
      continue;
    }
    
    kr = (*interface)->GetInterfaceSubClass(interface, &interfaceClass);
    if (kr) {
      NSLog(@"couldn't get interface sub-class (%08x)", kr);
      (*interface)->Release(interface);
      continue;
    }
    
    NSLog(@"interface class %d, subclass %d", interfaceClass,
          interfaceSubClass);
    
    kr = (*interface)->USBInterfaceOpen(interface);
    if (kr) {
      NSLog(@"unable to open interface (%08x)", kr);
      (*interface)->Release(interface);
      continue;
    }
    
    kr = (*interface)->GetNumEndpoints(interface, &interfaceNumEndpoints);
    if (kr) {
      NSLog(@"unable to get number of endpoints (%08x)", kr);
      (*interface)->USBInterfaceClose(interface);
      (*interface)->Release(interface);
      continue;
    }
    
    NSLog(@"interface has %d endpoints", interfaceNumEndpoints);
    
    for (pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++) {
      PrintPipeProperties(interface, pipeRef);
    }
    
    (*interface)->USBInterfaceClose(interface);
    (*interface)->Release(interface);
  }
  
  return kIOReturnSuccess;
}

// Finds the interface with the specified class and sub-class in the specified
// device. The device should be open.
IOReturn FindInterfaceWithClassSubClass(IOUSBDeviceInterface **device,
                                        UInt8 bInterfaceClass,
                                        UInt8 bInterfaceSubClass,
                                        IOUSBInterfaceInterface ***interface) {
  IOReturn kr;
  HRESULT hr;
  IOUSBFindInterfaceRequest request;
  io_iterator_t iterator;
  io_service_t usbInterface;
  IOCFPlugInInterface **plugIn = NULL;
  SInt32 score;
  
  *interface = NULL;
  
  request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
  request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
  request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
  request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
  
  kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
  if (kr) {
    NSLog(@"couldn't create interface iterator (%08x)", kr);
    return kr;
  }
  
  int interfaceCount = 0;
  while (usbInterface = IOIteratorNext(iterator)) {
    interfaceCount++;
    
    if (interfaceCount != 2) {
      continue;
    }
    
    kr = IOCreatePlugInInterfaceForService(usbInterface,
                                           kIOUSBInterfaceUserClientTypeID,
                                           kIOCFPlugInInterfaceID,
                                           &plugIn, &score);
    IOObjectRelease(usbInterface);
    if (kr || !plugIn) {
      NSLog(@"couldn't create plug-in for interface (%08x)", kr);
      continue;
    }
    
    hr = (*plugIn)->QueryInterface(
                                   plugIn,
                                   CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                   (LPVOID *) interface);
    
    (*plugIn)->Release(plugIn);
    
    if (hr || !interface) {
      NSLog(@"couldn't create interface for interface (%08x)", hr);
      continue;
    }
  }
  
  return kr;
}

// Gets the IOUSBDeviceInterface for an io_service_t USB device, but does not
// open the interface. Releases usbDevice; typically you want to work with the
// IOUSBDeviceInterface and not the io_service_t port.
IOReturn GetDeviceInterface(io_service_t usbDevice,
                            IOUSBDeviceInterface ***device) {
  kern_return_t kr;
  HRESULT hr;
  IOCFPlugInInterface **plugIn = NULL;
  SInt32 score;

  // create an intermediate plug-in for the device
  kr = IOCreatePlugInInterfaceForService(usbDevice,
                                         kIOUSBDeviceUserClientTypeID,
                                         kIOCFPlugInInterfaceID,
                                         &plugIn, &score);
  
  if (kr) {
    NSLog(@"couldn't create plug-in interface for device (%08x)", kr);
  }
  
  kr = IOObjectRelease(usbDevice);
  
  if (kr) {
    NSLog(@"unable to release keyboard device (%08x)\n", kr);
  }
  
  if (!plugIn) {
    return kIOReturnError;
  }
  
  // get the device interface
  
  hr = (*plugIn)->QueryInterface(plugIn,
                                 CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                 (LPVOID *) device);
  (*plugIn)->Release(plugIn);
  if (hr || !*device) {
    NSLog(@"couldn't get device interface (%08x)", hr);
    return kIOReturnError;
  }
  
  return kIOReturnSuccess;
}

void KeyboardDeviceAdded(void *context, io_iterator_t iterator) {
  kern_return_t kr;
  io_service_t usbDevice;
  IOUSBDeviceInterface **device = NULL;
  CFRunLoopSourceRef runLoopSource;
  UInt32 location;
  
  while (usbDevice = IOIteratorNext(iterator)) {
    NSLog(@"keyboard added %08x", (int) usbDevice);

    if (GetDeviceInterface(usbDevice, &device)) {
      continue;
    }
    
    kr = (*device)->GetLocationID(device, &location);
    if (kr) {
      NSLog(@"unable to get location of device (%08x)", kr);
      (*device)->Release(device);
      continue;
    }

    kr = (*device)->USBDeviceOpen(device);
    if (kr) {
      NSLog(@"couldn't open device (%08x)", kr);
      (*device)->Release(device);
      continue;
    }
    
    kr = ConfigureDevice(device);
    if (kr) {
      NSLog(@"unable to configure device (%08x)", kr);
      (*device)->USBDeviceClose(device);
      (*device)->Release(device);
      return;
    }
    
    //    kr = FindInterfaces(device);
    //    if (kr) {
    //      NSLog(@"couldn't enumerate interfaces (%08x)", kr);
    //    }
    
    // interface class 0, subclass 191
    // interface has 1 endpoint
    // PipeRef 1: direction out, transfer type interrupt, max packet size 64,
    // interval 1
    IOUSBInterfaceInterface **interface;
    kr = FindInterfaceWithClassSubClass(device, 0, 191, &interface);
    (*device)->USBDeviceClose(device);
    (*device)->Release(device);
    
    kr = (*interface)->USBInterfaceOpen(interface);
    if (kr) {
      NSLog(@"couldn't open interface (%08x)", kr);
      (*interface)->USBInterfaceClose(interface);
      (*interface)->Release(interface);
      continue;
    }
    
    // create an event source and add it to the run loop
    kr = (*interface)->CreateInterfaceAsyncEventSource(interface,
                                                       &runLoopSource);
    
    if (kr) {
      NSLog(@"couldn't create interface async event source (%08x)", kr);
      (*interface)->USBInterfaceClose(interface);
      (*interface)->Release(interface);
      continue;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
                       kCFRunLoopDefaultMode);
    CFRelease(runLoopSource);
    runLoopSource = NULL;

    KeyboardManager *keyboardManager = [KeyboardManager sharedInstance];
    Keyboard *keyboard = [[Keyboard alloc] initWithInterface:interface];
    (*interface)->Release(interface);
    [keyboard autorelease];
    [keyboardManager addKeyboard:keyboard at:location];
  }
}

void KeyboardDeviceRemoved(void *context, io_iterator_t iterator) {
  io_service_t usbDevice;

  while (usbDevice = IOIteratorNext(iterator)) {
    NSLog(@"keyboard removed");
    
    IOObjectRelease(usbDevice);
  }

  KeyboardManager *keyboardManager = [KeyboardManager sharedInstance];
  [keyboardManager keyboardRemoved];
}
