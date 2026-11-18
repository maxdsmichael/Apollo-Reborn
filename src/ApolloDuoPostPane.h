#import <UIKit/UIKit.h>

@interface ApolloDuoPostPane : UIViewController
- (instancetype)initWithPost:(id)post swapSides:(dispatch_block_t)swapSides showFeed:(dispatch_block_t)showFeed;
@property(nonatomic, readonly) NSObject *playbackToken;
@property(nonatomic, readonly) BOOL hasMedia;
@end
