#import "Repository.h"

@implementation Repository

@dynamic repoId;
@dynamic date;
@dynamic fullname;
@dynamic parentId;


-(id)init {
	repoId = 0;
	date = nil;
	fullname = nil;
	parentId = 0;
    return self;
}

// example: 123338:DylanFM/roro-faces,2009-05-31,13635
-(void)parse:(NSString*)repoDef {
	// NSArray *bigBits = [repoDef componentsSeparatedByString:@":"];
	// NSArray *listItems = [bigBits.first componentsSeparatedByString:@","];
}

-(int)repoId {
    return repoId;
}

-(NSString*)date {
    return date;
}

-(NSString*)fullname {
    return fullname;
}

-(int)parentId {
    return parentId;
}

@end
