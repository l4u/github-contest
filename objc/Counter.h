
#import <Foundation/Foundation.h>

@interface Counter : NSObject {
@private
    int value;
	
}

@property(nonatomic) int value;


-(NSComparisonResult)compareCounters: (id) other;

@end