#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
__BEGIN_DECLS
// The visible Posts host leases playback until its thread or tab disappears.
// Pinned players retain their pane token so late starts cannot revive a closed pane.
void ApolloDuoSetPlaybackScope(id host, UIView * _Nullable columns, id _Nullable pinnedToken);
void ApolloDuoEndPlaybackScope(id host);
void ApolloDuoTagPinnedPlayer(AVPlayer *player, id token);
__END_DECLS
NS_ASSUME_NONNULL_END
