//
//  DTPlayerControlViewDelegate.h
//  ijkplayerDemo
//
//  Created by Sam on 2017/7/31.
//  Copyright © 2017年 wanglei. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DTPlayerControlViewDelegate <NSObject>

@optional
/**  返回按钮事件 */
- (void)zf_controlView:(UIView *)controlView backAction:(UIButton *)sender;
/** 播放按钮事件 */
- (void)zf_controlView:(UIView *)controlView playAction:(UIButton *)sender;
/** 全屏按钮事件 */
- (void)zf_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender;
/** 锁定屏幕方向按钮时间 */
- (void)zf_controlView:(UIView *)controlView lockScreenAction:(UIButton *)sender;
/** 重播按钮事件 */
- (void)zf_controlView:(UIView *)controlView repeatPlayAction:(UIButton *)sender;
/** 中间播放按钮事件 */
- (void)zf_controlView:(UIView *)controlView cneterPlayAction:(UIButton *)sender;
/** 加载失败按钮事件 */
- (void)zf_controlView:(UIView *)controlView failAction:(UIButton *)sender;
/** slider的点击事件（点击slider控制进度） */
- (void)zf_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value;
/** 开始触摸slider */
- (void)zf_controlView:(UIView *)controlView progressSliderTouchBegan:(UISlider *)slider;
/** slider触摸中 */
- (void)zf_controlView:(UIView *)controlView progressSliderValueChanged:(UISlider *)slider;
/** slider触摸结束 */
- (void)zf_controlView:(UIView *)controlView progressSliderTouchEnded:(UISlider *)slider;

@end
