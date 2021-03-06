//
//  ViewController.h
//  ChillN
//
//  Created by Vincent Jardel on 26/03/2015.
//  Copyright (c) 2015 ChillCompany. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import <CircleProgressBar.h>
#import "ProutsApp-Swift.h"

@interface AddEventsViewController : UIViewController <AVAudioRecorderDelegate>

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) NSArray *friendsList;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendEventButton;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) NSData *datasound;
@property (strong, nonatomic) IBOutlet KYShutterButton *recordSoundButton;
@property (weak, nonatomic) IBOutlet CircleProgressBar *circleProgressBar;

@end
