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

#import "ApplicationDelegate.h"
#import "KeyboardManager.h"


@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // start listening for keyboards
  KeyboardManager *keyboardManager = [KeyboardManager sharedInstance];
  [keyboardManager start];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  KeyboardManager *keyboardManager = [KeyboardManager sharedInstance];
  [keyboardManager stop];
  [KeyboardManager releaseSharedInstance];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename {
  NSURL *url = [NSURL fileURLWithPath:filename];
  NSDocumentController *documentController =
      [NSDocumentController sharedDocumentController];
  id document = [documentController openDocumentWithContentsOfURL:url
                                                          display:YES
                                                            error:nil];
  return document != nil;
}

@end
