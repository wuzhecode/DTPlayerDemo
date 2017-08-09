//
//  MainViewController.m
//  DTIJKPlayer
//
//  Created by Sam on 2017/8/2.
//  Copyright © 2017年 dtedu. All rights reserved.
//

#import "MainViewController.h"
#import "PlayViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100 , 40)];
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"点播视频" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)click
{
    [self.navigationController pushViewController:[[PlayViewController alloc] init] animated:YES];
}
@end
