#import "ApolloDuoPostPane.h"
#import "ApolloGalleryFeed.h"
#import "ApolloGalleryImageViewer.h"
#import "ApolloGallerySource.h"
#import "Tweak.h"

@interface ApolloDuoPostPane ()
@property(nonatomic, strong) RDKLink *post;
@property(nonatomic, strong) ApolloGalleryFeed *feed;
@property(nonatomic, strong) UIView *content;
@property(nonatomic, copy) dispatch_block_t swapSides;
@end

@implementation ApolloDuoPostPane

- (instancetype)initWithPost:(id)post swapSides:(dispatch_block_t)swapSides {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _post = post;
        _swapSides = [swapSides copy];
        _feed = ApolloGalleryFeedForPost(post);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.view.clipsToBounds = YES;

    UIButton *swap = [UIButton buttonWithType:UIButtonTypeSystem];
    [swap setImage:[UIImage systemImageNamed:@"arrow.left.arrow.right"] forState:UIControlStateNormal];
    swap.accessibilityLabel = @"Swap Post and Comments";
    [swap addTarget:self action:@selector(swapPressed) forControlEvents:UIControlEventTouchUpInside];
    swap.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:swap];

    self.content = [UIView new];
    self.content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.content];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [swap.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [swap.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [swap.widthAnchor constraintEqualToConstant:44],
        [swap.heightAnchor constraintEqualToConstant:44],
        [self.content.topAnchor constraintEqualToAnchor:swap.bottomAnchor],
        [self.content.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.content.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.content.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    if (self.feed.items.firstObject.shouldBlurThumbnail) {
        UIButton *reveal = [UIButton buttonWithType:UIButtonTypeSystem];
        [reveal setTitle:@"Reveal Media" forState:UIControlStateNormal];
        [reveal addTarget:self action:@selector(revealMedia:) forControlEvents:UIControlEventTouchUpInside];
        reveal.translatesAutoresizingMaskIntoConstraints = NO;
        [self.content addSubview:reveal];
        [NSLayoutConstraint activateConstraints:@[
            [reveal.centerXAnchor constraintEqualToAnchor:self.content.centerXAnchor],
            [reveal.centerYAnchor constraintEqualToAnchor:self.content.centerYAnchor],
            [reveal.heightAnchor constraintGreaterThanOrEqualToConstant:44]
        ]];
    } else if (self.feed) {
        [self revealMedia:nil];
    } else {
        [self showPostText];
    }
}

- (void)swapPressed {
    self.swapSides();
}

- (void)revealMedia:(UIButton *)sender {
    [sender removeFromSuperview];
    ApolloGalleryImageViewer *viewer = [[ApolloGalleryImageViewer alloc] initWithFeed:self.feed initialIndex:0];
    viewer.embedded = YES;
    [self addChildViewController:viewer];
    viewer.view.frame = self.content.bounds;
    viewer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.content addSubview:viewer.view];
    [viewer didMoveToParentViewController:self];
}

- (void)showPostText {
    UITextView *text = [[UITextView alloc] initWithFrame:self.content.bounds];
    text.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    text.backgroundColor = UIColor.clearColor;
    text.editable = NO;
    text.adjustsFontForContentSizeCategory = YES;
    text.textContainerInset = UIEdgeInsetsMake(8, 16, 20, 16);

    NSString *title = self.post.title ?: @"";
    NSMutableAttributedString *body = [[NSMutableAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2],
        NSForegroundColorAttributeName: UIColor.labelColor
    }];
    NSString *postText = self.post.selfText;
    if (postText.length) {
        [body appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n\n" stringByAppendingString:postText]
            attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                         NSForegroundColorAttributeName: UIColor.labelColor}]];
    }
    NSURL *url = self.post.URL;
    NSString *scheme = url.scheme.lowercaseString;
    if (!self.post.isSelfPost && url.host.length &&
        ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"])) {
        [body appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n\n" stringByAppendingString:url.host]
            attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                         NSLinkAttributeName: url}]];
    }
    text.attributedText = body;
    [self.content addSubview:text];
}

@end
