//
//  ViewController.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "ViewController.h"
#import "AudioPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[AudioPlayer shareManager] creatPlayList:@[@"http://win.web.ra01.sycdn.kuwo.cn/resource/n1/192/29/57/3189494444.mp3",@"http://121.17.126.239/mp3.9ku.com/hot/2011/12-13/461514.mp3", @"http://win.web.re01.sycdn.kuwo.cn/resource/n2/85/26/3377023046.mp3"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)last:(id)sender {
}

- (IBAction)start:(id)sender {

    [[AudioPlayer shareManager] play];
}
- (IBAction)stop:(id)sender {
    [[AudioPlayer shareManager] pause];

}
- (IBAction)next:(id)sender {
    [[AudioPlayer shareManager] next];
}

@end
