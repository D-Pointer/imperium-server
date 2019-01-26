#ifndef PATHNODE_H
#define PATHNODE_H



typedef struct _position {
    int x;
    int y;
} Position;

@interface PathNode : NSObject {
@public
    // the total cost through this node
    float total;

    //! the cost so far to reach this node
    float costSoFar;

    //! an estimate of the rest
    float estimate;

    //! the position this node represents
    Position pos;

    //! the node that's before this
    PathNode * before;
    
    //unsigned int usage;
}

@end


@implementation PathNode

@end


//static int nodes = 0;

static PathNode * createPathNode (float costSoFar, float estimate, Position pos, PathNode * before) {
    PathNode * node = [PathNode new];
    //struct PathNode * node = (struct PathNode *)malloc( sizeof(struct PathNode) );
    node->total     = costSoFar + estimate;
    node->costSoFar = costSoFar;
    node->estimate  = estimate;
    node->pos       = pos;
    node->before    = before;
    //node->usage     = 0;

    //if ( node->before != nil ) {
    //    node->before->usage++;
    //}

    //nodes++;
    //CCLOG( @"nodes alive: %d", nodes );

    return node;
}


/*static void destroyPathNode (struct PathNode * node) {
    // is this node still used?
    if ( node->usage > 0 ) {
        return;
    }
    
    if ( node->before != nil ) {
        node->before->usage--;
        
        // anyone else using it?
        if ( node->before->usage == 0 ) {
            destroyPathNode( node->before );
        }
    }

    // not used, delete
    free( node );

    nodes--;
    CCLOG( @"nodes alive: %d", nodes );
}*/

#endif
