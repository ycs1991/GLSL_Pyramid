//
//  ViewController.m
//  GLSL_Pyramid
//
//  Created by 鲸鱼集团技术部 on 2020/8/1.
//  Copyright © 2020 com.sanqi.net. All rights reserved.
//

#import "ViewController.h"
#import "CSView.h"

@interface ViewController ()
@property (nonatomic, strong) CSView *csView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.csView = (CSView *)self.view;
}



@end
