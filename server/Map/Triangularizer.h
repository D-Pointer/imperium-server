
#import <Foundation/Foundation.h>

@interface Triangularizer : NSObject {

    CCArray * vertices;
    CCArray * indices;
}


- (CCArray *) triangularize:(CCArray *)originalVertices withSmoothing:(BOOL)smooth;

@end
