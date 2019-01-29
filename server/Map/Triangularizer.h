
#import <Foundation/Foundation.h>

@interface Triangularizer : NSObject {

     NSMutableArray * vertices;
     NSMutableArray * indices;
}


- ( NSMutableArray *) triangularize:(NSMutableArray *)originalVertices withSmoothing:(BOOL)smooth;

@end
