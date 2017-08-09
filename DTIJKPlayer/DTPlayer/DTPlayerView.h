//
//  DTPlayerView.h
//  ijkplayerDemo
//
//  Created by Sam on 2017/7/28.
//  Copyright © 2017年 wanglei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTPlayerControlViewDelegate.h"
#import "DTPlayerModel.h"
#import "DTPlayer.h"

// 返回按钮的block
typedef void(^ZFPlayerBackCallBack)(void);
@interface DTPlayerView : UIView <DTPlayerControlViewDelegate>

@property (nonatomic, strong) UIView                  *controlView;
@property (nonatomic, strong) DTPlayerModel           *playerModel;
@property (nonatomic, copy  ) NSString                *placeholderImageName;
@property (nonatomic, assign) NSInteger               seekTime;
@property (nonatomic, strong) NSURL                   *videoURL;
@property (nonatomic, copy  ) ZFPlayerBackCallBack    goBackBlock;
/** 是否开启预览图 */
@property (nonatomic, assign) BOOL                    hasPreviewView;
/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo;

- (void)playerControlView:(UIView *)controlView playerModel:(DTPlayerModel *)playerModel;

/**
 *  重置player
 */
- (void)resetPlayer;

/**
 *  播放
 */
- (void)play;

/**
 * 暂停
 */
- (void)pause;

/** 设置URL的setter方法 */
- (void)setVideoURL:(NSURL *)videoURL;

/**
 *  在当前页面，设置新的视频时候调用此方法
 */
- (void)resetToPlayNewVideo:(DTPlayerModel *)playerModel;

/**本地视频自动旋转 */
- (void)ownInterfaceOrientation:(UIInterfaceOrientation)orientation;
@end
