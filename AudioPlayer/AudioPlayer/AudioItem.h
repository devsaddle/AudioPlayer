//
//  AudioItem.h
//  AudioPlayer
//
//  Created by 马远 on 2017/7/13.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioItem : NSObject

/** ID 用来标示音频的唯一性 */
@property (nonatomic, copy) NSString *itemID;

/** 音频播放地址 */
@property (nonatomic, strong) NSURL *audioURL;



- (instancetype)initWithID:(NSString *)itemID url:(NSURL *)url;
+ (instancetype)itemWithID:(NSString *)itemID url:(NSURL *)url;
@end
