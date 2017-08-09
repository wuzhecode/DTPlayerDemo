//
//  DTPlayerModel.m
//  DTIJKPlayer
//
//  Created by Sam on 2017/8/2.
//  Copyright © 2017年 dtedu. All rights reserved.
//

#import "DTPlayerModel.h"
#import "DTPlayer.h"

@implementation DTPlayerModel

- (UIImage *)placeholderImage
{
    if (!_placeholderImage) {
        _placeholderImage = ZFPlayerImage(@"ZFPlayer_loading_bgView");
    }
    return _placeholderImage;
}

@end
