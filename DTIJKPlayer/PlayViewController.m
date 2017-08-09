//
//  PlayViewController.m
//  DTIJKPlayer
//
//  Created by Sam on 2017/8/2.
//  Copyright © 2017年 dtedu. All rights reserved.
//

#import "PlayViewController.h"
#import "DTPlayer.h"


@interface PlayViewController ()
@property (nonnull, strong) DTPlayerView *playerView;
@property (nonatomic, strong) UIButton *changeBtn;
@end

@implementation PlayViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
     [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupPlayer];
    
    //当前界面切换url
    self.changeBtn = [[UIButton alloc] initWithFrame:CGRectMake(150, 400, 100, 40)];
    self.changeBtn .backgroundColor = [UIColor blueColor];
    [self.changeBtn  setTitle:@"切换视频" forState:UIControlStateNormal];
    [self.view addSubview:self.changeBtn ];
    [self.changeBtn  addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
}

- (void)click
{
    DTPlayerModel *playereModel = [[DTPlayerModel alloc] init];
    playereModel.videoURL = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456231710844S(24).mp4"];
    [self.playerView resetToPlayNewVideo:playereModel];
    
}

- (void)setupPlayer
{
    
    UIView *topView = [[UIView alloc] init];
    topView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:topView];
    [topView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_offset(20);
    }];
    
    self.playerView = [[DTPlayerView alloc] init];
    [self.view addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(20);
        make.leading.trailing.mas_equalTo(0);
        // 这里宽高比16：9
        make.height.mas_equalTo(self.playerView.mas_width).multipliedBy(9.0f/16.0f);
    }];
    DTPlayerControlView *controlView = [[DTPlayerControlView alloc] init];
    DTPlayerModel *model = [[DTPlayerModel alloc] init];
    model.videoURL =  [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456231710844S(24).mp4"];
    [self.playerView playerControlView:controlView playerModel:model];
    [self.playerView autoPlayTheVideo];
    __weak typeof(self) weakself = self;
    self.playerView.goBackBlock = ^{
        [weakself.navigationController popViewControllerAnimated:YES];
    };
    
    
}

#pragma mark - 播放器视图旋转
-(BOOL)shouldAutorotate
{
    
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        self.view.backgroundColor = [UIColor whiteColor];
        //if use Masonry,Please open this annotation
        [self.playerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(20);
        }];
        
        
        
    }else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        self.view.backgroundColor = [UIColor blackColor];
        //if use Masonry,Please open this annotation
        //self.spokeCommitView.hidden = YES;
        
        [self.playerView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(0);
        }];
        
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


@end
