//
//  MQVoiceMessageCell.m
//  MeiQiaSDK
//
//  Created by ijinmao on 15/10/29.
//  Copyright © 2015年 MeiQia Inc. All rights reserved.
//

#import "MQVoiceMessageCell.h"
#import "MQVoiceCellModel.h"
#import "MQChatFileUtil.h"
#import "MQChatViewConfig.h"

static CGFloat const kMQChatCellDurationLabelFontSize = 13.0;

@implementation MQVoiceMessageCell {
    UIImageView *avatarImageView;
    UIImageView *bubbleImageView;
    UIActivityIndicatorView *sendMsgIndicator;
    UILabel *durationLabel;
    UIImageView *voiceImageView;
    UIImageView *failureImageView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //初始化头像
        avatarImageView = [[UIImageView alloc] init];
        avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:avatarImageView];
        //初始化气泡
        bubbleImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:bubbleImageView];
        //初始化indicator
        sendMsgIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        sendMsgIndicator.hidden = YES;
        [self.contentView addSubview:sendMsgIndicator];
        //初始化语音时长的label
        durationLabel = [[UILabel alloc] init];
        durationLabel.textColor = [UIColor lightGrayColor];
        durationLabel.font = [UIFont systemFontOfSize:kMQChatCellDurationLabelFontSize];
        durationLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:durationLabel];
        //初始化语音图片
        voiceImageView = [[UIImageView alloc] init];
        [bubbleImageView addSubview:voiceImageView];
        //初始化出错image
        failureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[MQChatViewConfig sharedConfig].messageSendFailureImage]];
        [self.contentView addSubview:failureImageView];
    }
    return self;
}

#pragma MQChatCellProtocol
- (void)updateCellWithCellModel:(id<MQCellModelProtocol>)model {
    if (![model isKindOfClass:[MQVoiceCellModel class]]) {
        NSAssert(NO, @"传给MQVoiceMessageCell的Model类型不正确");
        return ;
    }
    MQVoiceCellModel *cellModel = (MQVoiceCellModel *)model;
    
    //刷新头像
    if (cellModel.avatarPath.length == 0) {
        avatarImageView.image = cellModel.avatarLocalImage;
    } else {
#warning 使用SDWebImage或自己写获取远程图片的方法
    }
    avatarImageView.frame = cellModel.avatarFrame;
    
    //刷新气泡
    bubbleImageView.image = cellModel.bubbleImage;
    bubbleImageView.frame = cellModel.bubbleImageFrame;
    
    //消息图片
    voiceImageView.image = [UIImage imageNamed:[MQChatFileUtil resourceWithName:@"MQBubble_voice_animation_green3"]];
    NSString *animationImage1 = @"MQBubble_voice_animation_green1";
    NSString *animationImage2 = @"MQBubble_voice_animation_green2";
    NSString *animationImage3 = @"MQBubble_voice_animation_green3";
    if (cellModel.cellFromType == MQChatCellIncoming) {
        animationImage1 = @"MQBubble_voice_animation_gray1";
        animationImage2 = @"MQBubble_voice_animation_gray2";
        animationImage3 = @"MQBubble_voice_animation_gray3";
        voiceImageView.image = [UIImage imageNamed:[MQChatFileUtil resourceWithName:@"MQBubble_voice_animation_gray3"]];
    }
    voiceImageView.animationImages = [NSArray arrayWithObjects:
                                  [UIImage imageNamed:[MQChatFileUtil resourceWithName:animationImage1]],
                                  [UIImage imageNamed:[MQChatFileUtil resourceWithName:animationImage2]],
                                  [UIImage imageNamed:[MQChatFileUtil resourceWithName:animationImage3]],nil];
    
    //刷新indicator
    sendMsgIndicator.hidden = true;
    [sendMsgIndicator stopAnimating];
    if (cellModel.sendType == MQChatCellSending && cellModel.cellFromType == MQChatCellOutgoing) {
        sendMsgIndicator.frame = cellModel.indicatorFrame;
        [sendMsgIndicator startAnimating];
    }
    
    //刷新语音时长label
    NSString *durationText = [NSString stringWithFormat:@"%d\"", (int)cellModel.voiceDuration];
    durationLabel.text = durationText;
    durationLabel.frame = cellModel.durationLabelFrame;
    
    //刷新出错图片
    failureImageView.hidden = true;
    if (cellModel.sendType == MQChatCellSentFailure) {
        failureImageView.hidden = false;
        failureImageView.frame = cellModel.sendFailureFrame;
    }
}

/**
 *  开始播放声音
 */
- (void)didPlayVoice {
    [voiceImageView startAnimating];
}

/**
 *  停止播放声音
 */
- (void)didEndVoice {
    if (voiceImageView.isAnimating) {
        [voiceImageView stopAnimating];
    }
}



@end
