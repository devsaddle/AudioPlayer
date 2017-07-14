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
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgress;

@property (weak, nonatomic) IBOutlet UIButton *lastBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
  
    [[AudioPlayer shareManager] creatPlayList:@[  [AudioItem itemWithURL:[NSURL URLWithString:@"http://win.web.ra01.sycdn.kuwo.cn/resource/n1/192/29/57/3189494444.mp3"]]
                                                ,[AudioItem itemWithURL:[NSURL URLWithString:@"http://121.17.126.239/mp3.9ku.com/hot/2011/12-13/461514.mp3"]]
                                                ,[AudioItem itemWithURL:[NSURL URLWithString:@"http://win.web.re01.sycdn.kuwo.cn/resource/n2/85/26/3377023046.mp3"]]
                                                ]];
    
    [[AudioPlayer shareManager] playProgressValueChanged:^(AudioItem *currentItem,NSTimeInterval current, NSTimeInterval total) {
        [self.progressView setProgress:current/total animated:YES];
        self.timeLabel.text = [NSString stringWithFormat:@"%@/%@",[self formatPlayTime:current ],[self formatPlayTime:total]];
        
    }];
    
    [[AudioPlayer shareManager] loadProgressValueChanged:^(AudioItem *currentItem,NSTimeInterval current, NSTimeInterval total) {
        [self.bufferProgress setProgress:current/total animated:YES];
    }];
}


//将时间转换成00:00:00格式
- (NSString *)formatPlayTime:(NSTimeInterval)duration
{
    int minute = 0, hour = 0, secend = duration;
    minute = (secend % 3600)/60;
    hour = secend / 3600;
    secend = secend % 60;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, secend];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)last:(id)sender {
    BOOL last = [[AudioPlayer shareManager] last];
    self.lastBtn.enabled = last;
    
}

- (IBAction)start:(id)sender {

    [[AudioPlayer shareManager] play];
}
- (IBAction)stop:(id)sender {
    [[AudioPlayer shareManager] pause];

}
- (IBAction)next:(id)sender {
    BOOL next = [[AudioPlayer shareManager] next];
    self.nextBtn.enabled = next;
}

@end
