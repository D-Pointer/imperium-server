#import "BehaviorTree.h"
#import "Globals.h"

// nodes
#import "Composite.h"
#import "Decorator.h"
#import "Selector.h"
#import "Sequence.h"
#import "ConditionNode.h"

// see http://www.gamasutra.com/blogs/ChrisSimpson/20140717/221339/Behavior_trees_for_AI_How_they_work.php

@interface BehaviorTree () {
    // a base id used when including subtrees
    int baseId;

    // how much to increment the base id per subtree
    int baseIdIncrement;
}

@end

@implementation BehaviorTree

- (instancetype) init {
    self = [super init];
    if (self) {
        baseId = 0;
        baseIdIncrement = 1000;
    }

    return self;
}


- (void) executeWithContext:(BehaviorTreeContext *)context {
    // process the tree
    [self.root process:context];
}


- (BOOL) readTree:(NSString *)filename {
    self.root = [self readTreeInternal:filename];
    return self.root != nil;
}


- (Node *) readTreeInternal:(NSString *)filename {
    // this whole tree will use this base id
    int treeBaseId = baseId;

    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *scriptPath = [NSString stringWithFormat:@"%@/AI/%@", paths[0], filename];

    CCLOG( @"reading behavioral tree: %@, starting at base id: %d", scriptPath, treeBaseId );

    // read everything from text
    NSString *contents = [NSString stringWithContentsOfFile:scriptPath
                                                   encoding:NSUTF8StringEncoding error:nil];
    if (contents == nil) {
        CCLOG( @"file not found: %@", filename );
        return nil;
    }

    Node * root = nil;

    // created nodes
    NSMutableDictionary *createdNodes = [NSMutableDictionary new];

    // separate by new line
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    unsigned int nodeId, parentId;
    NSString * className;
    NSString * value = nil;
    NSString * comment;
    Node * node = nil;

    for (NSString *line in lines) {
        // split into parts
        NSArray *parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ( parts.count < 2 ) {
            continue;
        }

        // id 2
        // parent 1
        // type 0
        // class Sequence
        // value
        // comment Strategic level: hold

        NSString * key = parts[0];
        if ( [key isEqualToString:@"id"] ) {
            nodeId = treeBaseId + (unsigned int) [parts[1] integerValue];
        }

        else if ( [key isEqualToString:@"parent"] ) {
            parentId = (unsigned int) [parts[1] integerValue];
        }

        else if ( [key isEqualToString:@"value"] ) {
            value = parts[1];
        }

        else if ( [key isEqualToString:@"class"] ) {
            className = parts[1];
        }

        else if ( [key isEqualToString:@"comment"] ) {
            comment = [parts componentsJoinedByString:@" "];

            // now we have a complete node, create the node from the class name
            node = [[NSClassFromString( className ) alloc] init];
            if ( node == nil ) {
                CCLOG( @"did not find node for class: %@", className );
                NSAssert( NO, @"node class not found" );
            }

            // is this the root node?
            if (parentId == -1) {
                // this is the root
                root = node;
                root.level = 0;
                createdNodes[@(nodeId)] = root;
                continue;
            }

            // an include node?
            if ( [className isEqualToString:@"Include"] ) {
                // read the sub tree
                CCLOG( @"reading subtree %@", value );
                baseId += baseIdIncrement;
                node = [self readTreeInternal:value];
                if ( ! node ) {
                    CCLOG( @"failed to read subtree: %@", value );
                    NSAssert( NO, @"failed to read subtree" );
                }
            }

            else {
                // we're in the tree now, add the base id to the parent id too
                parentId += treeBaseId;
            }

            node.nodeId = nodeId;
            node.comment = comment;

            // any value?
            if ( value != nil ) {
                [node parseValue:value];

                // clear for the next node
                value = nil;
            }

            // save the node so that others can look it up
            createdNodes[@(nodeId)] = node;

            // find its parent
            Node *parent = createdNodes[ @(parentId) ];
            if (parent == nil) {
                CCLOG( @"parent %d not found for node: %@", parentId, node );
                NSAssert( NO, @"parent not found" );
            }

            if ( [parent isKindOfClass:[Composite class]] ) {
                // add the node to its parent
                [((Composite *) parent).children addObject:node];
            }
            else if ( [parent isKindOfClass:[Decorator class]] ) {
                // add the node to its parent
                ((Decorator *) parent).child = node;
            }

            node.level = parent.level + 1;
        }
    }
    
    CCLOG( @"loaded tree: %@", root );
    
    return root;
}



@end
