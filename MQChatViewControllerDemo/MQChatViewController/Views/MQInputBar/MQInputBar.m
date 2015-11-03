//
//  MQInputBar.m
//  MeChatSDK
//
//  Created by Injoy on 14-8-28.
//  Copyright (c) 2014年 MeChat. All rights reserved.
//

#import "MQInputBar.h"
#import "MQChatFileUtil.h"
#import "MQChatViewConfig.h"

//#define ButtonWidth 33
//#define ButtonX 6.5
static CGFloat const kMQInputBarHorizontalSpacing = 0;
static NSString * const kMQInputBarRecordButtonConfirmText = @"按住 说话";
static NSString * const kMQInputBarRecordButtonFinishText = @"松开 结束";

@interface MQInputBar()

//@property (nonatomic, weak) UIView *inputBarSuperView;

@end

@implementation MQInputBar
{
    CGRect originalFrame;   //默认
    CGRect originalSuperViewFrame;  //默认
    CGRect originalChatViewFrame;
    CGRect originalTextViewFrame;   //textView的初始frame
    
    //调整键盘需要涉及的变量
    UIEdgeInsets chatViewInsets;    //默认chatView.contentInsets
    float keyboardDifference;
    BOOL isInputBarUp;  //工具栏被抬高
    float bullleViewHeigth; //真实可视区域
    CGFloat senderImageWidth;
    CGFloat textViewHeight;
    MQChatTableView *chatTableView;
    BOOL enableRecord;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
          superView:(UIView *)inputBarSuperView
          tableView:(MQChatTableView *)tableView
    enableRecordBtn:(BOOL)enableRecordBtn
{
    if (self = [super init]) {
        self.frame              = frame;
        originalFrame           = frame;
//        self.superView               = inputBarSuperView;
        originalSuperViewFrame  = inputBarSuperView.frame;
        chatTableView           = tableView;
        originalChatViewFrame   = tableView.frame;

        senderImageWidth = [MQChatViewConfig sharedConfig].photoSenderImage.size.width;
        textViewHeight = ceil(frame.size.height * 5 / 7);
        
        self.backgroundColor = [UIColor whiteColor];
        cameraBtn              = [[UIButton alloc] init];
        [cameraBtn setImage:[MQChatViewConfig sharedConfig].photoSenderImage forState:UIControlStateNormal];
        [cameraBtn setImage:[MQChatViewConfig sharedConfig].photoSenderImage forState:UIControlStateHighlighted];
        [cameraBtn addTarget:self action:@selector(cameraClick) forControlEvents:UIControlEventTouchUpInside];
        cameraBtn.frame      = CGRectMake(kMQInputBarHorizontalSpacing, (self.frame.size.height - senderImageWidth)/2, senderImageWidth, senderImageWidth);
        
        self.textView               = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(0, 0, 0, textViewHeight)];
        self.textView.font          = [UIFont systemFontOfSize:16];
        self.textView.returnKeyType = UIReturnKeySend;
        self.textView.placeholder   = @"请输入...";
        self.textView.delegate      = (id)self;
        self.textView.layer.borderColor     = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        self.textView.layer.borderWidth     = 1;
        self.textView.layer.cornerRadius    = 4;
        
        enableRecord = false;
        if (enableRecordBtn) {
            enableRecord = true;
            [self initRecordBtn];
            
            self.textView.frame     = recordBtn.frame;
            originalTextViewFrame   = recordBtn.frame;
        }else{
            if (toolbarDownBtn) {
                toolbarDownBtn.hidden = YES;
            }
            if (microphoneBtn) {
                microphoneBtn.hidden = YES;
            }
            if (recordBtn) {
                recordBtn.hidden = YES;
            }
            self.textView.frame = CGRectMake(kMQInputBarHorizontalSpacing*2 + senderImageWidth, (originalFrame.size.height - textViewHeight)/2, originalFrame.size.width - kMQInputBarHorizontalSpacing * 3 - senderImageWidth, textViewHeight);
            originalTextViewFrame = self.textView.frame;
        }
        
        [self addSubview:self.textView];
        [self addSubview:cameraBtn];
        
        //给键盘注册通知
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputKeyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputKeyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toolbarDownBtnVisible)
                                                     name:UIKeyboardDidHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(toolbarDownBtnVisible)
                                                     name:@"MCToolbarDownBtnVisible"
                                                   object:nil];
        
    }
    return self;
}

-(void)initRecordBtn
{
    toolbarDownBtn = [[UIButton alloc] init];
    [toolbarDownBtn setImage:[UIImage imageNamed:[MQChatFileUtil resourceWithName:@"toolbarDown_normal"]] forState:UIControlStateNormal];
    [toolbarDownBtn setImage:[UIImage imageNamed:[MQChatFileUtil resourceWithName:@"toolbarDown_click"]] forState:UIControlStateHighlighted];
    [toolbarDownBtn addTarget:self action:@selector(toolbarDownClick) forControlEvents:UIControlEventTouchUpInside];
    toolbarDownBtn.hidden = YES;
    
    microphoneBtn = [[UIButton alloc] init];
    [microphoneBtn setImage:[MQChatViewConfig sharedConfig].voiceSenderImage forState:UIControlStateNormal];
    [microphoneBtn setImage:[MQChatViewConfig sharedConfig].voiceSenderImage forState:UIControlStateHighlighted];
    [microphoneBtn addTarget:self action:@selector(microphoneClick) forControlEvents:UIControlEventTouchUpInside];
    
    recordBtn                    = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordBtn setTitle:kMQInputBarRecordButtonConfirmText forState:UIControlStateNormal];
    [recordBtn setTitleColor:[UIColor colorWithWhite:.1 alpha:1] forState:UIControlStateNormal];
    recordBtn.backgroundColor    = [UIColor colorWithWhite:1 alpha:1];
    recordBtn.layer.cornerRadius = 4;
    recordBtn.alpha              = 0;
    recordBtn.hidden             = YES;
    
    recordBtn.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
    recordBtn.layer.borderWidth = 1;
    
    //        recordBtn.layer.shadowColor = [UIColor colorWithWhite:0 alpha:1].CGColor;
    //        recordBtn.layer.shadowOffset = CGSizeMake(0, .7);
    //        recordBtn.layer.shadowRadius = .6;
    //        recordBtn.layer.shadowOpacity = .4;
    
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recordBtnLongPressed:)];
    gesture.delegate = (id)self;
    gesture.delaysTouchesBegan = NO;
    gesture.delaysTouchesEnded = NO;
    gesture.minimumPressDuration = -1;
    [recordBtn addGestureRecognizer:gesture];
    
    microphoneBtn.frame = CGRectMake(self.frame.size.width - senderImageWidth - kMQInputBarHorizontalSpacing, (self.frame.size.height - senderImageWidth)/2, senderImageWidth, senderImageWidth);
    toolbarDownBtn.frame = microphoneBtn.frame;
    recordBtn.frame = CGRectMake(kMQInputBarHorizontalSpacing*2 + senderImageWidth, (originalFrame.size.height - textViewHeight)/2, originalFrame.size.width - kMQInputBarHorizontalSpacing * 4 - 2 * senderImageWidth, textViewHeight);
    
    [self addSubview:toolbarDownBtn];
    [self addSubview:recordBtn];
    [self addSubview:microphoneBtn];
}

-(void)cameraClick
{
    [self textViewResignFirstResponder];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"从相册选取",@"拍照", nil];
    [sheet showInView:self.superview];
}

-(void)toolbarDownClick
{
    microphoneBtn.hidden = NO;
    toolbarDownBtn.hidden = YES;
    [self resignFirstResponder];
}

-(void)microphoneClick
{
    if (recordBtn.hidden) {
        recordBtn.hidden = NO;
        [microphoneBtn setImage:[MQChatViewConfig sharedConfig].keyboardSenderImage forState:UIControlStateNormal];
        [microphoneBtn setImage:[MQChatViewConfig sharedConfig].keyboardSenderImage forState:UIControlStateHighlighted];
        [self textViewResignFirstResponder];
        [UIView animateWithDuration:.25 animations:^{
            //还原
            chatTableView.frame     = originalChatViewFrame;
            self.frame              = originalFrame;

            self.textView.frame     = originalTextViewFrame;
            self.textView.alpha     = 0;
            recordBtn.alpha         = 1;
            
            //居中
            [self functionBtnCenter];
        } completion:^(BOOL finished) {
            self.textView.hidden = YES;
        }];
    }else{
        [microphoneBtn setImage:[MQChatViewConfig sharedConfig].voiceSenderImage forState:UIControlStateNormal];
        [microphoneBtn setImage:[MQChatViewConfig sharedConfig].voiceSenderImage forState:UIControlStateHighlighted];
        [self.textView becomeFirstResponder];
        self.textView.hidden = NO;
        [UIView animateWithDuration:.25 animations:^{
            self.textView.text      = self.textView.text;
            self.textView.alpha     = 1;
            recordBtn.alpha         = 0;
        } completion:^(BOOL finished) {
            recordBtn.hidden        = YES;
        }];
    }
}

-(void)reRecordBtn
{
    [recordBtn setTitle:kMQInputBarRecordButtonConfirmText forState:UIControlStateNormal];
    [UIView animateWithDuration:.2 animations:^{
        recordBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    }];
}

- (void)recordBtnLongPressed:(UILongPressGestureRecognizer*) longPressedRecognizer{
    
    if(longPressedRecognizer.state == UIGestureRecognizerStateBegan) {
        if(self.delegate){
            if ([self.delegate respondsToSelector:@selector(beginRecord:)]) {
                [self.delegate beginRecord:[longPressedRecognizer locationInView:[[UIApplication sharedApplication] keyWindow]]];
            }
        }
        [recordBtn setTitle:kMQInputBarRecordButtonFinishText forState:UIControlStateNormal];
        [UIView animateWithDuration:.2 animations:^{
            recordBtn.backgroundColor = [UIColor colorWithWhite:.92 alpha:1];
        }];
    }else if(longPressedRecognizer.state == UIGestureRecognizerStateEnded || longPressedRecognizer.state == UIGestureRecognizerStateCancelled) {
        [self endRecordWithPoint:[longPressedRecognizer locationInView:[[UIApplication sharedApplication] keyWindow]]];
        [recordBtn setTitle:kMQInputBarRecordButtonConfirmText forState:UIControlStateNormal];
        [UIView animateWithDuration:.2 animations:^{
            recordBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        }];
    }else if(longPressedRecognizer.state == UIGestureRecognizerStateChanged) {
        [self changeRecordStatusWithPoint:[longPressedRecognizer locationInView:[[UIApplication sharedApplication] keyWindow]]];
    }
}

//改变录音的状态
- (void)changeRecordStatusWithPoint:(CGPoint)point {
    if ([self isFingerMoveUpToCancelRecordingWithPoint:point]) {
        //取消录音状态
        if(self.delegate){
            if ([self.delegate respondsToSelector:@selector(changedRecordViewToCancel:)]) {
                [self.delegate changedRecordViewToCancel:point];
            }
        }
    } else {
        //正常录音状态
        if(self.delegate){
            if ([self.delegate respondsToSelector:@selector(changedRecordViewToNormal:)]) {
                [self.delegate changedRecordViewToNormal:point];
            }
        }
    }
}

//结束录音，并判断是取消录音还是完成录音
- (void)endRecordWithPoint:(CGPoint)point {
    if ([self isFingerMoveUpToCancelRecordingWithPoint:point]) {
        //取消录音
        if(self.delegate){
            if ([self.delegate respondsToSelector:@selector(cancelRecord:)]) {
                [self.delegate cancelRecord:point];
            }
        }
    } else {
        //结束录音
        if(self.delegate){
            if ([self.delegate respondsToSelector:@selector(finishRecord:)]) {
                [self.delegate finishRecord:point];
            }
        }
    }
}

//判断手指是否上移取消发送
- (BOOL)isFingerMoveUpToCancelRecordingWithPoint:(CGPoint)point {
    float y = 0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        y = [[UIApplication sharedApplication] keyWindow].frame.size.height - self.frame.size.height - point.y;
    }else{
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft || statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
            y = point.x;
        }else{
            y = [[UIApplication sharedApplication] keyWindow].frame.size.height - self.frame.size.height - point.y;
        }
    }
    if (y + 20 > 100) {
        return YES;
    }else{
        return NO;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: {
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(sendImageWithSourceType:)]) {
                    [self.delegate sendImageWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                }
            }
            break;
        }
        case 1: {
            if (self.delegate) {
                if ([self.delegate respondsToSelector:@selector(sendImageWithSourceType:)]) {
                    [self.delegate sendImageWithSourceType:(NSInteger*)UIImagePickerControllerSourceTypeCamera];
                }
            }
            break;
        }
    }
    actionSheet = nil;
}

-(void)inputKeyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if (self.textView.isFirstResponder) {
        float keyboardHeight;
        
        //兼用ios8及以上
        if ([[UIDevice currentDevice].systemVersion intValue] <= 7) {
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft || statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
                keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.width;
            }else{
                keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
            }
        }else{
            keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
        }
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(chatTableViewScrollToBottom)]) {
                [self.delegate chatTableViewScrollToBottom];
            }
        }
        [self moveToolbarUp:keyboardHeight animate:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
        [self moveToolbarUp:keyboardHeight animate:.25];
        [self toolbarDownBtnVisible];
    }
}

-(void)inputKeyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    [self moveToolbarDown:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
}

-(void)textViewResignFirstResponder
{
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

-(void)moveToolbarUp:(float)height animate:(NSTimeInterval)duration
{
    if (!isInputBarUp){
        bullleViewHeigth = chatTableView.frame.size.height - chatTableView.contentInset.top;
        chatViewInsets   = chatTableView.contentInset;
    }
    
    //内容与键盘的高度差。   可视区域 - 键盘高度 - 总内容高度
    keyboardDifference  = bullleViewHeigth - height - chatTableView.contentSize.height;
    /*
     去要调整contentInset.top的情况：
     1、keyboardDifference大于0，说明内容不饱和，及contentInset.top加上键盘高度
     2、keyboardDifference小于0，contentInset.top加上bullleViewHeigth再加keyboardDifference（相当于减，因为keyboardDifference为负数），但keyboardDifference的绝对值不能超过bullleViewHeigth
     */
    [UIView animateWithDuration:duration animations:^{
        if(keyboardDifference >= 0){
            chatTableView.contentInset = UIEdgeInsetsMake(chatViewInsets.top + height,
                                                     chatViewInsets.left,
                                                     chatViewInsets.bottom,
                                                     chatViewInsets.right);
        }else{
            //限制keyboardDifference大小
            if (-keyboardDifference > bullleViewHeigth) keyboardDifference = -bullleViewHeigth;
            chatTableView.contentInset = UIEdgeInsetsMake(chatTableView.contentInset.top + keyboardDifference + bullleViewHeigth,
                                                     chatTableView.contentInset.left,
                                                     chatTableView.contentInset.bottom,
                                                     chatTableView.contentInset.right);
        }
        self.superview.frame = CGRectMake(self.superview.frame.origin.x,
                                          originalSuperViewFrame.origin.y - height,
                                          self.superview.frame.size.width,
                                          self.superview.frame.size.height);
    }];

    isInputBarUp = YES;
}

-(void)moveToolbarDown:(float)animateDuration
{
    [UIView animateWithDuration:animateDuration
                     animations:^{
                         self.superview.frame  = originalSuperViewFrame;
                         chatTableView.contentInset = chatViewInsets;
                     } completion:^(BOOL finished) {
                         isInputBarUp = NO;
                     }];
}

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView
{
    [self sendText:nil];
    return YES;
}

-(void)sendText:(id)sender
{
    if ([self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        if (self.delegate) {
            if ([self.delegate respondsToSelector:@selector(sendTextMessage:)]) {
                if([self.delegate sendTextMessage:self.textView.text]) {
                    [self.textView setText:@""];
                }
            }
        }
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(inputting:)]) {
            [self.delegate inputting:self.textView.text];
        }
    }
}

-(void)toolbarDownBtnVisible
{
    if (!enableRecord) {
        return;
    }
    
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (statusBarOrientation == UIInterfaceOrientationLandscapeLeft || statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        if ([self.textView isFirstResponder]) {
            microphoneBtn.hidden = YES;
            toolbarDownBtn.hidden = NO;
        }else{
            microphoneBtn.hidden = NO;
            toolbarDownBtn.hidden = YES;
        }
    }else{
        microphoneBtn.hidden = NO;
        toolbarDownBtn.hidden = YES;
    }
}

-(void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff     = (self.textView.frame.size.height - height);
    //确保tableView的y不大于原始的y
    CGFloat tableViewOriginY = chatTableView.frame.origin.y + diff;
    if (tableViewOriginY > originalChatViewFrame.origin.y) {
        tableViewOriginY = originalChatViewFrame.origin.y;
    }
    chatTableView.frame = CGRectMake(chatTableView.frame.origin.x, tableViewOriginY, chatTableView.frame.size.width, chatTableView.frame.size.height);
    self.frame     = CGRectMake(0, self.frame.origin.y + diff, self.frame.size.width, self.frame.size.height - diff);
    
    //居中
    [self functionBtnCenter];
}

-(void)functionBtnCenter
{
    cameraBtn.frame      = CGRectMake(kMQInputBarHorizontalSpacing, (self.frame.size.height - senderImageWidth)/2, senderImageWidth, senderImageWidth);
    microphoneBtn.frame = CGRectMake(self.frame.size.width - senderImageWidth - kMQInputBarHorizontalSpacing, (self.frame.size.height - senderImageWidth)/2, senderImageWidth, senderImageWidth);
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.8 alpha:1].CGColor);
    CGContextMoveToPoint(ctx, 0, 0);
    CGContextAddLineToPoint(ctx, rect.size.width, 0);
    CGContextClosePath(ctx);
    CGContextStrokePath(ctx);
}

@end
