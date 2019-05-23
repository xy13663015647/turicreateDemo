//
//  ViewController.m
//  TestApp
//
//  Created by user on 2019/5/14.
//  Copyright © 2019 zzcb. All rights reserved.
//

#import "ViewController.h"
#import "TZImagePickerController.h"//照片
#import "UIView+frame.h"
#import "UIImage+Rotate.h"
#import "objectTracking.h"
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>

#define screenWidth  ([UIScreen mainScreen].bounds.size.width)
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define mixNume 0.3
#define nms_threshold 0.45

struct Prediction {
    NSInteger labelIndex;
    CGFloat confidence;
    CGRect boundingBox;
};
typedef struct Prediction Prediction;

@interface ViewController ()<TZImagePickerControllerDelegate>{
    UIButton *selectImgBtn;
    NSInteger detectionNum; //检测次数
}

@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIView *boxView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.view.backgroundColor = [UIColor grayColor];
    
    [self initViews];
    [self.view addSubview:self.infoLabel];
    [self.view addSubview:self.boxView];
    
}

#pragma mark - UI
- (UILabel *)infoLabel{
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, SCREENHEIGHT - 80, SCREENWIDTH - 80, 30)];
        _infoLabel.textColor = [UIColor redColor];
        _infoLabel.backgroundColor = [UIColor grayColor];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _infoLabel;
}

- (UIView *)boxView{
    if (!_boxView) {
        _boxView = [[UIView alloc] initWithFrame:CGRectZero];
        _boxView.layer.borderColor = [UIColor redColor].CGColor;
        _boxView.layer.borderWidth = 2;
        _boxView.backgroundColor = [UIColor blueColor];
    }
    return _boxView;
}

- (void)initViews{
    //选择图片
    selectImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    selectImgBtn.frame = CGRectMake(0, 64, screenWidth, screenWidth);
    [selectImgBtn setImage:[UIImage imageNamed:@"icon_addImg"] forState:UIControlStateNormal];
    selectImgBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:selectImgBtn];
    [selectImgBtn addTarget:self action:@selector(pickImage) forControlEvents:UIControlEventTouchUpInside];
    selectImgBtn.backgroundColor = [UIColor grayColor];
}

- (void)pickImage{
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    imagePickerVc.allowPickingOriginalPhoto = NO;//设置不能发送原图
    imagePickerVc.allowPickingVideo = NO;//设置不能发送视频
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark 照片相关
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    
    [selectImgBtn setImage:photos[0] forState:UIControlStateNormal];
    [self objectDetectionWithImage:photos[0]];
    
}


- (void)objectDetectionWithImage:(UIImage *)newPhoto{
   
    newPhoto = [UIImage imageWithCGImage:newPhoto.CGImage scale:1.0 orientation:UIImageOrientationRight];
    newPhoto = [newPhoto fixOrientation];
    
    objectTracking *model = [[objectTracking alloc] init];
    VNCoreMLModel *coreMLModel = [VNCoreMLModel modelForMLModel:model.model error:nil];
    VNCoreMLRequest *request = [[VNCoreMLRequest alloc] initWithModel:coreMLModel completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        CGFloat confidence = 0.0f;
        
        VNClassificationObservation *tempClassification = nil;
        
        for (VNClassificationObservation *classification in request.results) {
            if (classification.confidence > confidence) {
                confidence = classification.confidence;
                tempClassification = classification;
            }
        }
        
        self.infoLabel.text = [NSString stringWithFormat:@"识别结果:%@匹配率:%@",tempClassification.identifier,@(tempClassification.confidence)];

    }];
    
    VNImageRequestHandler *vnImageRequestHandler = [[VNImageRequestHandler alloc] initWithCGImage:newPhoto.CGImage options:nil];
    
    NSError *error = nil;
    [vnImageRequestHandler performRequests:@[request] error:&error];
    
    if (error) {
        NSLog(@"%@",error.localizedDescription);
    }
}

@end
