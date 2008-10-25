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

#import "DraggableEffectArrayController.h"

#import "Effect.h"
#import "MyDocument.h"


@implementation DraggableEffectArrayController

- (id) init {
  return [super init];
}

-(void)insertObject:(Effect *)effect
atArrangedObjectIndex:(NSUInteger)index
     withActionName:(NSString *)actionName {
  if (document) {
    NSUndoManager *undo = [document undoManager];
    [[undo prepareWithInvocationTarget:self]
     removeObjectAtArrangedObjectIndex:index
     withActionName:actionName];
    if (![undo isUndoing]) {
      [undo setActionName:actionName];      
    }
    [(MyDocument*) document startObservingEffect:effect];
  }
  [super insertObject:effect atArrangedObjectIndex:index];
}

-(void)removeObjectAtArrangedObjectIndex:(NSUInteger)index
                          withActionName:(NSString *)actionName {
  if (document) {
    NSUndoManager *undo = [document undoManager];
    Effect *effect = [[self arrangedObjects] objectAtIndex:index];
    [[undo prepareWithInvocationTarget:self]
     insertObject:effect atArrangedObjectIndex:index withActionName:actionName];
    if (![undo isUndoing]) {
      [undo setActionName:actionName];
    }
    [(MyDocument*) document stopObservingEffect:effect];
  }
  [super removeObjectAtArrangedObjectIndex:index];  
}


- (void)insertObject:(Effect *)effect atArrangedObjectIndex:(NSUInteger)index {
  NSString *actionName;
  if ([[self arrangedObjects] indexOfObject:effect] == NSNotFound) {
    actionName = [NSString stringWithFormat:@"Insert %@", [effect name]];
  } else {
    actionName = [NSString stringWithFormat:@"Move %@", [effect name]];
  }
  [self insertObject:effect
atArrangedObjectIndex:index
      withActionName:actionName];
}

- (void)removeObjectAtArrangedObjectIndex:(NSUInteger)index {
  Effect *effect = [[self arrangedObjects] objectAtIndex:index];
  NSString *actionName =
      [NSString stringWithFormat:@"Remove %@", [effect name]];
  [self removeObjectAtArrangedObjectIndex:index withActionName:actionName];
}

- (BOOL)tableView:(NSTableView *)tableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard *)pb {
  
  // TODO: setDraggingSourceOperationMask w/ local
  
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
  [pb declareTypes:[NSArray arrayWithObject:[Effect pasteboardType]]
             owner:self];
  [pb setData:data forType:[Effect pasteboardType]];
  return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView
                 validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(int)row
        proposedDropOperation:(NSTableViewDropOperation)op {
  NSArray *types = [[info draggingPasteboard] types];
  if ([types containsObject:[Effect pasteboardType]]) {
    if (op == NSTableViewDropOn) {
      [tableView setDropRow:row dropOperation:NSTableViewDropAbove]; 
    }
    
    return tableView == [info draggingSource]
        ? NSDragOperationMove
        : NSDragOperationCopy;
  } else {
    return NSDragOperationNone;
  }
}

- (void)moveObjectAtArrangedObjectIndex:(NSUInteger)sourceIndex
                                toIndex:(NSUInteger)destinationIndex {

  Effect *effect = [[self arrangedObjects] objectAtIndex:sourceIndex];
  
  if (document) {
    NSUndoManager *undo = [document undoManager];
    [[undo prepareWithInvocationTarget:self]
        moveObjectAtArrangedObjectIndex:destinationIndex
                                toIndex:sourceIndex];
    if (![undo isUndoing]) {
      [undo setActionName:[NSString stringWithFormat:@"Move %@",
                           [effect name]]];
    }
  }
  
  // remove from source
  [super removeObjectAtArrangedObjectIndex:sourceIndex];
  
  // insert at destination
  [super insertObject:effect atArrangedObjectIndex:destinationIndex];
}

- (BOOL) tableView:(NSTableView *)tableView
        acceptDrop:(id <NSDraggingInfo>)info
               row:(int)row
     dropOperation:(NSTableViewDropOperation)operation {
  NSPasteboard *pb = [info draggingPasteboard];
  NSData *data = [pb dataForType:[Effect pasteboardType]];
  NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  // TODO: this assumes that the source is an NSTableView
  NSTableView *sourceTableView = (NSTableView *)[info draggingSource];

  // TODO: this assumes single selection only
  int sourceIndex = [rowIndexes firstIndex];
  Effect *effect =
      [[[sourceTableView dataSource] arrangedObjects] objectAtIndex:sourceIndex];
  
  if (tableView == [info draggingSource]) {
    [self moveObjectAtArrangedObjectIndex:sourceIndex
                                  toIndex:row - (sourceTableView == tableView
                                                 && sourceIndex < row ? 1 : 0)];
  } else {
    // copy
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:effect];
    effect = (Effect *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self insertObject:effect atArrangedObjectIndex:row];
  }
  
  return YES;
}

@end
