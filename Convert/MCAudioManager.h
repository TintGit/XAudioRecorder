//
//  AudioManager.h
//  PCMTest
//
//  Created by yanming on 2018/9/10.
//  Copyright © 2018年 wakeup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

@interface MCAudioManager : NSObject
typedef void (^RecordConvertBlock)(NSString*errorInfo);

- (void)audioPCMtoMP3:(NSString *)cafFilePath filePath:(NSString *)mp3FilePath withBlock:(RecordConvertBlock)block;
@end
