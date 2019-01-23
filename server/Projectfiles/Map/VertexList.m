
#import "VertexList.h"


@implementation VertexList

@synthesize size;

- (id) init {
    self = [super init];

    if (self) {
		iterator = NULL;
		head = NULL;
        iterator = NULL;
        self.size = 0;
    }
    
    return self;
}


/* Instantiates new linked list with a 
 * given first element. 
 */
- (id)initWithHead: (CGPoint)value {
    self = [super init];

    if (self) {
		// creating head node with given value
		ListNode * n = (ListNode *)malloc(sizeof(ListNode));
		n->value = value;
		n->next = NULL;
		n->prev = NULL;
		head = n;

		// initializing iterator to default
		[self getFirst];
        
        self.size = 1;
    }
    return self;	
}


/* Adds a new element to the
 * front of the list */
- (void)addToFront: (CGPoint)value {
	ListNode *n = (ListNode *)malloc(sizeof(ListNode));
	n->value = value;
    
    // empty list?
    if ( head == NULL ) {
		n->next = NULL;
		n->prev = NULL;
		head = n;
    }
    else {
        // new element becomes the head node
        head->prev = n;
        n->next = head;
        n->prev = NULL;
        head = n;
    }
    
    self.size += 1;
}


/* Sets internal iterator to
 * the head node and returns its
 * value */
- (CGPoint)getFirst {
    NSAssert( self.size > 0, @"List empty" );

	iterator = head;
	return head->value;
}

/* Returns the value of the iterator node
 */
- (CGPoint)getCurrent {
    NSAssert( self.size > 0, @"List empty" );
	return iterator->value;
}


/* Iterates to the next node in order and
 * returns its value */
- (CGPoint)getNext {
    NSAssert( self.size > 0, @"List empty" );

    if (iterator->next != NULL) {
        iterator = iterator->next;
    }
    return iterator->value;
}


/* Iterates to the previous node in 
 * order and returns its value */
- (CGPoint)getPrevious {
    NSAssert( self.size > 0, @"List empty" );

    if (iterator->prev != NULL) {
        iterator = iterator->prev;
    }
    
    return iterator->value;
}


/* Indicates that iterator
 * is at the first (head) node */
- (bool)atHead {
    NSAssert( self.size > 0, @"List empty" );

    return (iterator->prev == NULL);
}


/* Indicates that iterator
 * is at the last (tail) node */
- (bool)atTail {
    NSAssert( self.size > 0, @"List empty" );

    return iterator->next == NULL;
}


/* Removes the iterator node from
 * the list and advances iterator to the
 * next element. If there's no next element,
 * then it backs iterator up to the previous
 * element. Returns the old iterator value */
- (CGPoint)removeCurrent {
    NSAssert( self.size > 0, @"List empty" );

	CGPoint i = iterator->value;
	ListNode *l;
    
	// if we have only 1 item in the list...
	if ((iterator->next == NULL) && (iterator->prev == NULL)) {
		//... then we can safely delete it and set head to null
		free(iterator);
		iterator = NULL;
		head = NULL;
        self.size = 0;
	} 
    
    else {
		// sawing the gap between nodes
		l = iterator;
		if (iterator->next != NULL) {
			iterator->next->prev = iterator->prev;
		}
		if (iterator->prev != NULL) {
			iterator->prev->next = iterator->next;
		}
        
        // if removing node is head, set head.
        if(iterator == head) {
            head = iterator->next;
        }
        
		// finally setting new iterator
		iterator = (iterator->next != NULL) ? iterator->next : iterator->prev;
		free(l);
        
        self.size -= 1;
	}
    
	// returning old value
	return i;
}

@end