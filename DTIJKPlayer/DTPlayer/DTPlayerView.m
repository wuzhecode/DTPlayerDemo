//
//  DTPlayerView.m
//  ijkplayerDemo
//
//  Created by Sam on 2017/7/28.
//  Copyright © 2017年 wanglei. All rights reserved.
//

#import "DTPlayerView.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "ZFBrightnessView.h"
#import "UIView+CustomControlView.h"
#import "DTPlayer.h"

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};
@interface DTPlayerView ()<UIGestureRecognizerDelegate,UIAlertViewDelegate>



/** 播放属性 */
@property (atomic, strong) id <IJKMediaPlayback> player;
@property (nonatomic, strong) NSTimer *                     timeObserve;
/** 滑杆 */
@property (nonatomic, strong) UISlider               *volumeViewSlider;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;
/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;
/** 是否为全屏 */
@property (nonatomic, assign) BOOL                   isFullScreen;
/** 是否锁定屏幕方向 */
@property (nonatomic, assign) BOOL                   isLocked;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;
/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL                   isPauseByUser;
/** 是否播放本地文件 */
@property (nonatomic, assign) BOOL                   isLocalVideo;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat                sliderLastValue;
/** 是否再次设置URL播放视频 */
@property (nonatomic, assign) BOOL                   repeatToPlay;
/** 播放完了*/
@property (nonatomic, assign) BOOL                   playDidEnd;
/** 进入后台*/
@property (nonatomic, assign) BOOL                   didEnterBackground;
/** 是否自动播放 */
@property (nonatomic, assign) BOOL                   isAutoPlay;
/** 单击 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
/** 双击 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
/** 视频URL的数组 */
@property (nonatomic, strong) NSArray                *videoURLArray;
/** slider预览图 */
@property (nonatomic, strong) UIImage                *thumbImg;
/** 播放器view的父视图 */
@property (nonatomic, strong) UIView                 *fatherView;
/** 亮度view */
@property (nonatomic, strong) ZFBrightnessView       *brightnessView;

/** 是否正在拖拽 */
@property (nonatomic, assign) BOOL                   isDragged;

@end
@implementation DTPlayerView

/**
 *  代码初始化调用此方法
 */
- (instancetype)init
{
    self = [super init];
    if (self) { [self initializeThePlayer]; }
    return self;
}

/**
 *  初始化player
 */
- (void)initializeThePlayer
{
    // 每次播放视频都解锁屏幕锁定
    [self unLockTheScreen];
}

- (void)dealloc
{

    ZFPlayerShared.isLockScreen = NO;
    [self.controlView zf_playerCancelAutoFadeOutControlView];
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    // 移除time观察者
    if (self.timeObserve) {
        [self.timeObserve invalidate];
        self.timeObserve = nil;
    }
}


#pragma mark - layoutSubviews

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutIfNeeded];
    self.player.view.frame = self.bounds;
    [UIApplication sharedApplication].statusBarHidden = NO;
    // 4s，屏幕宽高比不是16：9的问题,player加到控制器上时候
    if (iPhone4s) {
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_offset(ScreenWidth*2/3);
        }];
    }
    
}

/**
 *  自动播放，默认不自动播放
 */
- (void)autoPlayTheVideo
{
    // 设置Player相关参数
    [self configZFPlayer];
}


#pragma mark -Player相关参数
- (void)configZFPlayer
{
    self.backgroundColor = [UIColor blackColor];
    if (!self.playerModel.videoURL) {
        NSLog(@"没有可播放的视频资源");
    }
    BOOL res = NO;
    if (_player) {
        [_player stop];
        [_player shutdown];
        [_player.view removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }else
    {
        res = YES;
    }
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame" ofCategory:kIJKFFOptionCategoryCodec];
    [options setOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter" ofCategory:kIJKFFOptionCategoryCodec];
    [options setOptionIntValue:0 forKey:@"videotoolbox" ofCategory:kIJKFFOptionCategoryPlayer];
    [options setOptionIntValue:60 forKey:@"max-fps" ofCategory:kIJKFFOptionCategoryPlayer];
    [options setPlayerOptionIntValue:256 forKey:@"vol"];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.playerModel.videoURL withOptions:options];
    //设置填充模式
    [self.player setScalingMode:IJKMPMovieScalingModeFill];
    // 自动播放
    self.isAutoPlay = YES;
    // 获取系统音量
    [self configureVolume];
    //添加通知
    [self installMovieNotificationObservers];
    [self.player prepareToPlay];
    self.isPauseByUser = NO;

}

#pragma mark - public method

- (void)playerControlView:(UIView *)controlView playerModel:(DTPlayerModel *)playerModel
{
    self.controlView = controlView;
    self.playerModel = playerModel;
}

- (void)resetToPlayNewVideo:(DTPlayerModel *)playerModel
{
    self.playerModel = playerModel;
    [self configZFPlayer];

}

/**
 *  解锁屏幕方向锁定
 */
- (void)unLockTheScreen
{
    // 调用AppDelegate单例记录播放状态是否锁屏
    ZFPlayerShared.isLockScreen = NO;
    [self.controlView zf_playerLockBtnState:NO];
    self.isLocked = NO;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - 添加定时器
- (void)createTimer
{
    self.timeObserve = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(playerTimerAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timeObserve forMode:NSRunLoopCommonModes];

}

#pragma mark - 计时器事件
/**
 *  计时器事件
 */
- (void)playerTimerAction
{
    NSInteger currentTime = (NSInteger)self.player.currentPlaybackTime;
    CGFloat totalTime     = (CGFloat)_player.duration;
    CGFloat value         = _player.currentPlaybackTime /_player.duration;//当前进度;
    //时刻更新播放时间
    [self.controlView zf_playerCurrentTime:currentTime totalTime:totalTime sliderValue:value];
}

/**
 *  获取系统音量
 */
- (void)configureVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    
    // 监听耳机插入和拔掉通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

#pragma mark - 手势 点击和双击
/**
 *  创建手势
 */
- (void)createGesture
{
    // 单击
    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    self.singleTap.delegate                = self;
    self.singleTap.numberOfTouchesRequired = 1; //手指数
    self.singleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.singleTap];
    
    // 双击(播放/暂停)
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    self.doubleTap.delegate                = self;
    self.doubleTap.numberOfTouchesRequired = 1; //手指数
    self.doubleTap.numberOfTapsRequired    = 2;
    
    [self addGestureRecognizer:self.doubleTap];
    
    // 解决点击当前view时候响应其他控件事件
    [self.singleTap setDelaysTouchesBegan:YES];
    [self.doubleTap setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isAutoPlay) {
        UITouch *touch = [touches anyObject];
        if(touch.tapCount == 1) {
            [self performSelector:@selector(singleTapAction:) withObject:@(NO) ];
        } else if (touch.tapCount == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTapAction:) object:nil];
            [self doubleTapAction:touch.gestureRecognizers.lastObject];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UISlider class]]) {//如果是进度条则不接受self的手势操作
        return NO;
    }
    
    return YES;
}
#pragma Install Notifiacation

- (void)installMovieNotificationObservers {
    //准备播放
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    //第一帧
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerFirstVideoFrame:)
                                                 name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification
                                               object:nil];
    //加载状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
   
    //播放状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    //播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    //视频跳转成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackSeekFinish:) name:IJKMPMoviePlayerDidSeekCompleteNotification object:_player];
}

- (void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerFirstVideoFrameRenderedNotification object:_player];
    
     [[NSNotificationCenter defaultCenter] removeObserver:self name:IJKMPMoviePlayerDidSeekCompleteNotification object:_player];
}

#pragma mark NSNotificationCenter
//准备播放
- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    if (notification.object != self.player) {
        return;
    }
    IJKFFMoviePlayerController * play = self.player;
    NSLog(@"videotoolbox %@",@([play isVideoToolboxOpen]));
    NSLog(@"onPlayerPrepared");
    //准备播放时添加播放的view
    [self setNeedsLayout];
    [self layoutIfNeeded];
   [self.layer insertSublayer:self.player.view.layer atIndex:0];
    // 隐藏占位图
    [self.controlView zf_playerItemPlaying];
    // 添加playerLayer到self.layer
 //   [self.layer insertSublayer:self.player.view.layer atIndex:0];
   
}
//视频渲染第一帧
- (void)onPlayerFirstVideoFrame:(NSNotification *)notification
{
    if (notification.object != self.player) {
        return;
    }
   
    [self.controlView zf_playerPlayBtnState:YES];
    NSLog(@"onPlayerFirstVideoFrame");
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        // 加载完成后，再添加平移手势
        // 添加平移手势，用来控制音量、亮度、快进快退
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDirection:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [self addGestureRecognizer:panRecognizer];
        //添加计数器
        [self createTimer];
        // 跳到xx秒播放视频
        if (self.playerModel.seekTime) {
           // [self seekToTime:self.playerModel.seekTime completionHandler:nil];
        }
        
    }else if((loadState & IJKMPMovieLoadStateStalled) != 0)
    {
//        //显示loading条
//        [self.controlView zf_playerActivity:YES];
//        //暂停播放
//        [self.player pause];
        NSLog(@"加载状态变成了数据缓存已经停止，播放将暂停");
    }else if((loadState & IJKMPMovieLoadStatePlayable) != 0){
//        //隐藏loading条
//        [self.controlView zf_playerActivity:NO];
//        //播放
//        [self.player play];
    }
    else if (loadState == IJKMPMovieLoadStateUnknown) {//网络不佳，缓冲

        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    }else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}


//播放状态变化
- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    if (notification.object != self.player) {
        return;
    }
    IJKMPMoviePlaybackState state = self.player.playbackState;
    switch (state) {
        case IJKMPMoviePlaybackStatePlaying:
        {
          
            //[self setPlayerState:MFStationPlayerStatePlaying notification:notification];
            NSLog(@"moviePlayBackStateDidChange: IJKMPMoviePlaybackStatePlaying:\n");
        }
            break;
        case IJKMPMoviePlaybackStatePaused:
        {
           // [self setPlayerState:MFStationPlayerStatePaused notification:notification];
            NSLog(@"moviePlayBackStateDidChange: IJKMPMoviePlaybackStatePaused:\n");
        }
            break;
        case IJKMPMoviePlaybackStateStopped:
        {
            //[self setPlayerState:MFStationPlayerStateStopped notification:notification];
             NSLog(@"moviePlayBackStateDidChange: IJKMPMoviePlaybackStateStopped:\n");
        }
            break;
        case IJKMPMoviePlaybackStateInterrupted:
        {
        NSLog(@"moviePlayBackStateDidChange: IJKMPMoviePlaybackStateInterrupted:\n");
        }
            break;
        case IJKMPMoviePlaybackStateSeekingForward:
        {
        NSLog(@"moviePlayBackStateDidChange: IJKMPMoviePlaybackStateSeekingForward:\n");
        }
            break;
      
        default:
            break;
    }
}
//播放完成
- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"播放结束当前是%f秒,总时长%f秒",_player.currentPlaybackTime,_player.duration);
            if (!self.isDragged) { // 如果不是拖拽中，直接结束播放
                self.playDidEnd = YES;
                [self.controlView zf_playerPlayEnd];
            }
           
            
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            //播放失败
             [self.controlView zf_playerItemStatusFailed:nil];
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

//跳转视频成功
- (void)moviePlayBackSeekFinish:(NSNotification*)notification {
    
    NSLog(@"跳转视频成功");
    NSLog(@"当前跳转到%f秒",_player.currentPlaybackTime);
    //拖拽结束
    self.isDragged = NO;
    [self.player play];
    //影藏菊花进度条
    [self.controlView zf_playerActivity:NO];
    [self.controlView zf_playerDraggedEnd];
}
#pragma mark - UIPanGestureRecognizer手势方法
/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
                // 给sumTime初值
                self.sumTime    = self.player.currentPlaybackTime;
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    self.isPauseByUser = NO;
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value
{
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value
{
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CGFloat totalMovieDuration = self.player.duration;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    
    self.isDragged = YES;
    [self.controlView zf_playerDraggedTime:self.sumTime totalTime:totalMovieDuration isForward:style hasPreview:NO];
}



/**
 *   轻拍方法
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)singleTapAction:(UIGestureRecognizer *)gesture
{
    NSLog(@"单击");

    if ([gesture isKindOfClass:[NSNumber class]] && ![(id)gesture boolValue]) {
       // [self _fullScreenAction];
        return;
    }
    if (gesture.state == UIGestureRecognizerStateRecognized) {
     
        if (self.playDidEnd) {
            return;
        }
        else {//显示控制界面
            [self.controlView zf_playerShowControlView];
        }
        
    }
}

/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UIGestureRecognizer *)gesture
{
    if (self.playDidEnd) { return;  }
    // 显示控制层
    [self.controlView zf_playerCancelAutoFadeOutControlView];
    [self.controlView zf_playerShowControlView];
    if (!self.player.isPlaying)
    {
        [self play];
    }
    else {
        [self pause];
    }
//    if (!self.isAutoPlay) {
//        self.isAutoPlay = YES;
//        [self configZFPlayer];
//    }
}

#pragma mark - 跳转视频
/**
 *  从xx秒开始播放视频跳转
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler
{
   
    [self.controlView zf_playerActivity:YES];
    [self.player pause];
    _player.currentPlaybackTime = dragedSeconds;
    
  
}


#pragma mark - action
/**
 *  播放
 */
- (void)play
{
    //设置播放按钮状态
    [self.controlView zf_playerPlayBtnState:YES];
    [_player play];
    // 显示控制层
    [self.controlView zf_playerCancelAutoFadeOutControlView];
    [self.controlView zf_playerShowControlView];

}

/**
 * 暂停
 */
- (void)pause
{
    //设置播放按钮状态
    [self.controlView zf_playerPlayBtnState:NO];
    [_player pause];
}

/** 全屏 */
- (void)_fullScreenAction
{
    if (ZFPlayerShared.isLockScreen) {
        [self unLockTheScreen];
        return;
    }
    if (self.isFullScreen) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        self.isFullScreen = NO;
        return;
    } else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        self.isFullScreen = YES;
    }
}

#pragma mark - 屏幕旋转相关的
/**
 *  强制屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    // arc下
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector             = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val                  = orientation;
        // 从2开始是因为0 1 两个参数已经被selector和target占用
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }

}

/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange
{
    if (!self.player) { return; }
    if (ZFPlayerShared.isLockScreen) { return; }
    if (self.didEnterBackground) { return; };
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    
   
    if (ZFPlayerOrientationIsLandscape || orientation == UIDeviceOrientationPortraitUpsideDown) {
        self.isFullScreen = YES;
    } else {
        self.isFullScreen = NO;
    }
    
}

- (void)toOrientation:(UIInterfaceOrientation)orientation
{
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) { return; }
    
    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
            ZFBrightnessView *brightnessView = [ZFBrightnessView sharedBrightnessView];
            [[UIApplication sharedApplication].keyWindow insertSubview:self belowSubview:brightnessView];
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(ScreenHeight));
                make.height.equalTo(@(ScreenWidth));
                make.center.equalTo(self.superview);
            }];
        }
    }
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    [UIView setAnimationDuration:0.3];
    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];
    [self.controlView layoutIfNeeded];
    [self.controlView setNeedsLayout];
}

/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformRotationAngle
{
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}


#pragma mark - setter

/**
 *  videoURL的setter方法
 *
 *  @param videoURL videoURL
 */
- (void)setVideoURL:(NSURL *)videoURL
{
    _videoURL = videoURL;
    
    // 每次加载视频URL都设置重播为NO
    self.repeatToPlay = NO;
    self.playDidEnd   = NO;
    
    // 添加通知
    //[self addNotifications];
    
   // self.isPauseByUser = YES;
    
    // 添加手势
    [self createGesture];
    
    
    
}

/**
 *  设置播放视频前的占位图
 *
 *  @param placeholderImageName 占位图的图片名称
 */
- (void)setPlaceholderImageName:(NSString *)placeholderImageName
{
    _placeholderImageName = placeholderImageName;
    if (placeholderImageName) {
        UIImage *image = [UIImage imageNamed:self.placeholderImageName];
        self.playerModel.placeholderImage = image;
    }else {
        UIImage *image = ZFPlayerImage(@"ZFPlayer_loading_bgView");
        self.playerModel.placeholderImage = image;
    }
    [self.controlView zf_playerModel:self.playerModel];
}


- (void)setControlView:(UIView *)controlView
{
    if (_controlView) { return; }
    _controlView = controlView;
    controlView.delegate = self;
    [self addSubview:controlView];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.bottom.equalTo(self);
    }];
}

- (void)setPlayerModel:(DTPlayerModel *)playerModel
{
    _playerModel = playerModel;
    
    if (playerModel.seekTime) { self.seekTime = playerModel.seekTime; }
    [self.controlView zf_playerModel:playerModel];
    self.videoURL = playerModel.videoURL;
}

#pragma mark - ZFPlayerControlViewDelegate

- (void)zf_controlView:(UIView *)controlView playAction:(UIButton *)sender
{
    if (self.player.isPlaying) {
        [self pause];
    } else {
        [self play];
    }
    
//    if (!self.isAutoPlay) {
//        self.isAutoPlay = YES;
//        [self configZFPlayer];
//    }
}

- (void)zf_controlView:(UIView *)controlView backAction:(UIButton *)sender
{
    if (ZFPlayerShared.isLockScreen) {
        [self unLockTheScreen];
    } else {
        if (!self.isFullScreen || self.isLocalVideo) {
            // player加到控制器上，只有一个player时候
            [self pause];
            self.fatherView = nil;
            if (self.goBackBlock) {
                [self.player pause];
                [self.player shutdown];
                
                self.player = nil;
                self.goBackBlock();
            }
        } else {
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
    }
}

- (void)zf_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender
{
    [self _fullScreenAction];
}

- (void)zf_controlView:(UIView *)controlView repeatPlayAction:(UIButton *)sender
{
    // 没有播放完
    self.playDidEnd   = NO;
    // 重播改为NO
    self.repeatToPlay = NO;
    [self configZFPlayer];
}

- (void)zf_controlView:(UIView *)controlView progressSliderValueChanged:(UISlider *)slider
{
    NSLog(@"%ld,%ld",self.player.loadState,self.player.playbackState);
    // 拖动改变视频播放进度
    if (self.player.isPreparedToPlay) {
        self.isDragged = YES;
        BOOL style = false;
        CGFloat value   = slider.value - self.sliderLastValue;
        if (value > 0) { style = YES; }
        if (value < 0) { style = NO; }
        if (value == 0) { return; }
        
        self.sliderLastValue  = slider.value;
        
        CGFloat totalTime     = (CGFloat)_player.duration;
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(totalTime * slider.value);

        
        [controlView zf_playerDraggedTime:dragedSeconds totalTime:totalTime isForward:style hasPreview:self.isFullScreen ? self.hasPreviewView : NO];
        
        if (totalTime > 0) { // 当总时长 > 0时候才能拖动slider
            if (self.isFullScreen && self.hasPreviewView) {
                
               
            }
        } else {
            // 此时设置slider值为0
            slider.value = 0;
        }
        
    }else { // player状态加载失败
        // 此时设置slider值为0
        slider.value = 0;
    }
    
}

- (void)zf_controlView:(UIView *)controlView progressSliderTouchEnded:(UISlider *)slider
{
    if (self.player.isPreparedToPlay) {
        self.isPauseByUser = NO;
        self.isDragged = NO;
        // 视频总时间长度
        CGFloat total           = (CGFloat)_player.duration;
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * slider.value);
        [self seekToTime:dragedSeconds completionHandler:nil];
    }
}

- (void)zf_controlView:(UIView *)controlView failAction:(UIButton *)sender
{
    [self configZFPlayer];
}
@end
