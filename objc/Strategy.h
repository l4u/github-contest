
#import <Foundation/Foundation.h>

#import "Model.h"

@interface Strategy : NSObject {

@private
	Model *model;
}

@property(readonly, nonatomic) Model *model;

-(id)initWithModel:(Model *)aModel;
-(void)calculatePredictions;

@end
