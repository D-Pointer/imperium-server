// Structure representing a 
// doubly-linked list node.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef struct ListNode ListNode;
struct ListNode {
	CGPoint value;
	ListNode *next;
	ListNode *prev;
};


@interface VertexList : NSObject {
@private 
	ListNode *head;
	ListNode *iterator;
}	

@property (nonatomic) int size;

- (id)initWithHead: (CGPoint)value;
- (void)addToFront: (CGPoint)value;
- (CGPoint)getFirst;
- (CGPoint)getCurrent;
- (CGPoint)getNext;
- (CGPoint)getPrevious;

- (bool)atHead;
- (bool)atTail;

- (CGPoint)removeCurrent;

@end
