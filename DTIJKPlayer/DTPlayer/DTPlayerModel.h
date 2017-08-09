#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DTPlayerModel : NSObject
/** 视频标题 */
@property (nonatomic, copy  ) NSString     *title;
/** 视频URL */
@property (nonatomic, strong) NSURL        *videoURL;
/** 视频封面本地图片 */
@property (nonatomic, strong) UIImage      *placeholderImage;
/**
 * 视频封面网络图片url
 * 如果和本地图片同时设置，则忽略本地图片，显示网络图片
 */
@property (nonatomic, copy  ) NSString     *placeholderImageURLString;
/** 视频分辨率 */
@property (nonatomic, strong) NSDictionary *resolutionDic;
/** 从xx秒开始播放视频(默认0) */
@property (nonatomic, assign) NSInteger    seekTime;
// cell播放视频，以下属性必须设置值
@property (nonatomic, strong) UITableView  *tableView;
/** cell所在的indexPath */
@property (nonatomic, strong) NSIndexPath  *indexPath;
/** playerView所在的父视图tag值 */
@property (nonatomic, assign) NSInteger    cellImageViewTag;



@end
