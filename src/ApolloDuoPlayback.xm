#import "ApolloDuoPlayback.h"
#import "ApolloCommon.h"
#import <objc/runtime.h>

static NSObject *sLock;
static __weak id sHost;
static id sPinned;
static __weak AVPlayer *sPlaying;
static char kPinnedToken;
static NSHashTable<AVPlayer *> *sUnscopedPlayers;

static void ApolloDuoPauseColumnPlayers(CALayer *layer) {
    if ([layer isKindOfClass:AVPlayerLayer.class]) {
        AVPlayer *player = ((AVPlayerLayer *)layer).player;
        [player pause]; // Includes players waiting for a network buffer.
    }
    for (CALayer *child in layer.sublayers) ApolloDuoPauseColumnPlayers(child);
}

void ApolloDuoSetPlaybackScope(id host, UIView *columns, id token) {
    @synchronized (sLock) {
        if (sHost == host && sPinned == token) return;
        [sPlaying pause];
        sPlaying = nil;
        sHost = host;
        sPinned = token;
        for (AVPlayer *player in sUnscopedPlayers.allObjects) [player pause];
        [sUnscopedPlayers removeAllObjects];
        ApolloDuoPauseColumnPlayers(columns.layer);
    }
}

void ApolloDuoEndPlaybackScope(id host) {
    @synchronized (sLock) {
        if (sHost != host) return;
        if (sPinned) [sPlaying pause];
        else if (sPlaying) [sUnscopedPlayers addObject:sPlaying];
        sPlaying = nil;
        sPinned = nil;
        sHost = nil;
    }
}

void ApolloDuoTagPinnedPlayer(AVPlayer *player, id token) {
    objc_setAssociatedObject(player, &kPinnedToken, token, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Native visibility callbacks, buffered starts, the loop handler and the
// scrubber can all request playback independently. Serialize the actual start
// with the previous pause, including calls arriving off the UI thread. Zero
// rates always pass through (including AVPlayer's implementation of pause).
static void ApolloDuoStartPlayer(AVPlayer *player, void (^start)(void)) {
    id token = objc_getAssociatedObject(player, &kPinnedToken);
    @synchronized (sLock) {
        if (!sHost) {
            if (token) return;
            [sUnscopedPlayers addObject:player];
            start();
            return;
        }
        if (token != sPinned) return;
        if (sPlaying != player) {
            [sPlaying pause];
            sPlaying = player;
        }
        start();
    }
}

%hook AVPlayer
- (void)play {
    ApolloDuoStartPlayer(self, ^{ %orig; });
}
- (void)playImmediatelyAtRate:(float)rate {
    if (!rate) { %orig; return; }
    ApolloDuoStartPlayer(self, ^{ %orig; });
}
- (void)setRate:(float)rate {
    if (!rate) { %orig; return; }
    ApolloDuoStartPlayer(self, ^{ %orig; });
}
- (void)setRate:(float)rate time:(CMTime)time atHostTime:(CMTime)hostTime {
    if (!rate) { %orig; return; }
    ApolloDuoStartPlayer(self, ^{ %orig; });
}
%end

%ctor {
    if (!ApolloDeviceIsDuo()) return;
    sLock = [NSObject new];
    sUnscopedPlayers = [NSHashTable weakObjectsHashTable];
    %init;
}
