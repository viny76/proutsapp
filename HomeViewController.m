//
//  ViewController.m
//  ChillN
//
//  Created by Vincent Jardel on 26/03/2015.
//  Copyright (c) 2015 ChillCompany. All rights reserved.
//

#import "HomeViewController.h"
#import "HomeCell.h"
#import "AppDelegate.h"
#import "AddEventsViewController.h"
#import "EventDetailViewController.h"
#import "CustomFonts.h"
#import "Screen.h"
#import <AddressBook/AddressBook.h>
#import "CBZSplashView.h"
#import "UIColor+CustomColors.h"
#import "ProutsApp-Swift.h"

@interface HomeViewController()
@end

@implementation HomeViewController
NSTimer *sliderTimer;

#define Rgb2UIColor(r, g, b)  [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0) blue:((b) / 255.0) alpha:1.0]
NSURL *soundFileUrl;
NSData *soundData;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sampleData = [[NSMutableArray alloc] init];
    self.myRate = [[NSArray alloc] init];
    [self configureAppearance];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    self.currentUser = [PFUser currentUser];
    [self reloadFriend];
    
    // Launch Timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //reloadEvents
    refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl beginRefreshing];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(reloadEvents) forControlEvents:UIControlEventValueChanged];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    if (!self.currentUser.objectId) {
        [PFUser logOut];
        AppDelegate *appDelegateTemp = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        UIViewController *rootController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"LoginViewController"];
        
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:rootController];
        appDelegateTemp.window.rootViewController = navigation;
    } else {
        [self reloadEvents];
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView; {
    return self.sampleData.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section; {
    return self.sampleData[section][@"createdAt"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section; {
    return [self.sampleData[section][@"group"] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // iPhone 6
    int totalDisplayZone = [Screen height]-self.navigationController.navigationBar.frame.size.height-[UIApplication sharedApplication].statusBarFrame.size.height;
    if ([Screen height] > 568) {
        return totalDisplayZone/6;
    } else {
        return totalDisplayZone/4;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    // Background color
    view.tintColor = [UIColor colorWithHexString:@"4054B2"];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"parallaxCell";
    HomeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFObject *post = self.sampleData[indexPath.section][@"group"][indexPath.row];
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", [post objectForKey:@"fromUser"]];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // Add the following line to display the time in the local time zone
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"HH:mm"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC+2"]];
    cell.hourLabel.text = [formatter stringFromDate:post.createdAt];
    
    PFRelation *relation = [post relationForKey:@"Rate"];
    PFQuery *query = [relation query];
    // Get Rate
    if (![[post objectForKey:@"fromUserId"] isEqualToString:[PFUser currentUser].objectId]) {
        [query whereKey:@"eventId" equalTo:post.objectId];
        [query whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if (object) {
                cell.starRatingView.value = [[object valueForKey:@"rate"] floatValue];
            }
        }];
    } else {
        cell.starRatingView.enabled = NO;
        [query whereKey:@"eventId" equalTo:post.objectId];
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (objects) {
                cell.starRatingView.value = [[[objects valueForKey:@"rate"] valueForKeyPath:@"@avg.floatValue"] floatValue];
            } else {
                cell.starRatingView.value = 0;
            }
        }];
    }
    
    NSInteger rowNumber = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        rowNumber += [self.tableView numberOfRowsInSection:i];
    }
    
    rowNumber += indexPath.row;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, self.tableView.frame.size.width, [tableView rectForRowAtIndexPath:indexPath].size.height);
    //    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithHexString:@"2980b9"] CGColor], (id)[[UIColor colorWithHexString:@"2c3e50"] CGColor], nil];
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithHexString:@"F0F0F0"] CGColor], (id)[[UIColor colorWithHexString:@"AEAEAE"] CGColor], nil];
    [cell.contentView.layer insertSublayer:gradient atIndex:0];
    
    //    switch (rowNumber % 2) {
    //        case 0:
    //            cell.contentView.backgroundColor = Rgb2UIColor(125, 216, 171);
    //            break;
    //        case 1:
    //            cell.contentView.backgroundColor = [UIColor colorWithHexString:@"0E66F1"];
    //            break;
    //            //        case 2:
    //            //            cell.contentView.backgroundColor = [UIColor colorWithHexString:@"0E66F1"];
    //            //            break;
    //            //        case 3:
    //            //            cell.contentView.backgroundColor = [UIColor colorWithHexString:@"1871FD"];
    //            //            break;
    //
    //        default:
    //            break;
    //    }
    
    return cell;
}

- (int)getPosition:(int)section rowNumber:(int)row {
    int position = 0;
    for (int i = 0; i < section; i++) {
        position += [self.sampleData[i] count];
    }
    return position + row;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setBackgroundColor:[UIColor clearColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    PFObject *post = self.sampleData[indexPath.section][@"group"][indexPath.row];
    self.selectedEvent = post;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *post = self.sampleData[indexPath.section][@"group"][indexPath.row];
    PFUser *user = [post objectForKey:@"fromUserId"];
    if ([user  isEqual: [[PFUser currentUser] objectId]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFObject *object = self.sampleData[indexPath.section][@"group"][indexPath.row];
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self reloadEvents];
            } else {
                NSLog(@"error");
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addEvents"]) {
        AddEventsViewController *viewController = (AddEventsViewController *)segue.destinationViewController;
        viewController.friendsList = self.friends;
        viewController.currentUser = self.currentUser;
    } else if ([segue.identifier isEqualToString:@"detailEvent"]) {
        EventDetailViewController *viewController = (EventDetailViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        PFObject *post = self.sampleData[indexPath.section][@"group"][indexPath.row];
        viewController.event = post;
        viewController.currentUser = self.currentUser;
    }
}

- (void)reloadEvents {
    PFQuery *eventsQuery1 = [PFQuery queryWithClassName:@"Events"];
    [eventsQuery1 whereKey:@"toUserId" equalTo:[[PFUser currentUser] objectId]];
    
    PFQuery *eventsQuery2 = [PFQuery queryWithClassName:@"Events"];
    [eventsQuery2 whereKey:@"fromUserId" equalTo:[[PFUser currentUser] objectId]];
    
    PFQuery *eventsQuery = [PFQuery orQueryWithSubqueries:@[eventsQuery1,eventsQuery2]];
    [eventsQuery orderByDescending:@"createdAt"];
    
    if (eventsQuery) {
        [eventsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            } else {
                // We found messages!
                
                // Sort array by NSDate
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                // Add the following line to display the time in the local time zone
                [formatter setTimeZone:[NSTimeZone systemTimeZone]];
                [formatter setDateFormat:@"dd/MM/yyyy"];
                [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
                
                // Sparse dictionary, containing keys for "days with posts"
                NSMutableDictionary *daysWithPosts = [NSMutableDictionary dictionary];
                
                [objects enumerateObjectsUsingBlock:^(PFObject *object, NSUInteger idx, BOOL *stop) {
                    NSString *dateString = [formatter stringFromDate:object.createdAt];
                    // Check to see if we have a day already.
                    NSMutableArray *posts = [daysWithPosts objectForKey: dateString];
                    
                    // If not, create it
                    if (posts == nil || (id)posts == [NSNull null]) {
                        posts = [NSMutableArray arrayWithCapacity:1];
                        [daysWithPosts setObject:posts forKey: dateString];
                    }
                    
                    // add post to day
                    [posts addObject:object];
                }];
                
                // Sort Dictionary Keys by Date
                NSArray *unsortedSectionTitles = [daysWithPosts allKeys];
                NSArray *sortedSectionTitles = [unsortedSectionTitles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSDate *date1 = [formatter dateFromString:obj1];
                    NSDate *date2 = [formatter dateFromString:obj2];
                    return [date2 compare:date1];
                }];
                
                NSMutableArray *sortedData = [NSMutableArray arrayWithCapacity:sortedSectionTitles.count];
                
                // Put Data into correct format:
                [sortedSectionTitles enumerateObjectsUsingBlock:^(NSString *dateString, NSUInteger idx, BOOL *stop) {
                    NSArray *group = daysWithPosts[dateString];
                    NSDictionary *dictionary = @{ @"createdAt":dateString,
                                                  @"group":group};
                    [sortedData addObject:dictionary];
                }];
                
                self.sampleData = sortedData;
                [refreshControl endRefreshing];
                [self.tableView reloadData];
                
                // Restart Timer
                self.ticks = 0;
            }
        }];
    }
}

- (void)configureAppearance {
    // Navigation bar
//    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]]; // this will change the back button tint
//    [self.navigationController.navigationBar setBarTintColor:[UIColor colorChillin]];
//    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    //    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    self.tableView.backgroundColor = [UIColor colorChillin];
    [self.tableView.backgroundView setContentMode:UIViewContentModeScaleAspectFill];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIImage *icon = [UIImage imageNamed:@"AppIcon"];
    CBZSplashView *splashView = [CBZSplashView splashViewWithIcon:icon backgroundColor:[UIColor colorChillin]];
    
    // customize duration, icon size, or icon color here;
    splashView.animationDuration = 1.4;
    [self.view addSubview:splashView];
    [splashView startAnimation];
    
    //UIButton in UIBarButtonItem
    self.eventsButton.showsTouchWhenHighlighted = YES;
    self.eventsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.eventsButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.friendsButton.showsTouchWhenHighlighted = YES;
    self.friendsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.friendsButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.menuButton.showsTouchWhenHighlighted = YES;
}

- (void)timerTick:(NSTimer *)timer {
    self.ticks += 1.0;
    double seconds = fmod(self.ticks, 60.0);
    double minutes = fmod(trunc(self.ticks / 60.0), 60.0);
    double hours = trunc(self.ticks / 3600.0);
    if (hours != 0) {
        self.timerString = [NSString stringWithFormat:@"Rafraîchit il y a %2.0fh%02.0f", hours, minutes];
    } else if (minutes != 0) {
        if (minutes > 9) {
            self.timerString = [NSString stringWithFormat:@"Rafraîchit il y a %02.0fmin", minutes];
        } else {
            self.timerString = [NSString stringWithFormat:@"Rafraîchit il y a %2.0fmin", minutes];
        }
    } else {
        self.timerString = [NSString stringWithFormat:@"Rafraîchit il y a %2.0fsec", seconds];
    }
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:self.timerString];
}

- (void)reloadFriend {
    PFQuery *friendsQuery = [[self.currentUser relationForKey:@"friends"] query];
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        } else {
            self.friends = objects;
        }
    }];
}

- (IBAction)playSound:(UIButton *)sender {
    [sender setImage:[UIImage imageNamed:@"replay"] forState:UIControlStateNormal];
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    PFObject *event = self.sampleData[indexPath.section][@"group"][indexPath.row];
    PFFile *soundFile = [event objectForKey:@"soundFile"];
    soundFileUrl = [[NSURL alloc] initWithString:soundFile.url];
    soundData = [[NSData alloc] initWithContentsOfURL:soundFileUrl options:NSDataReadingMappedIfSafe error:nil ];
    self.player = [[AVAudioPlayer alloc] initWithData:soundData error:nil];
    
    if (sliderTimer) {
        [sliderTimer invalidate];
    }
    
    [self.player setDelegate:self];
    [self.player prepareToPlay];
    [self.player play];
    
    NSMutableDictionary *cb = [[NSMutableDictionary alloc] init];
    [cb setObject:indexPath forKey:@"indexPath"];
    [cb setObject:sender forKey:@"sender"];
    sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePlayProgress:) userInfo:cb repeats:YES];
}

- (void)updatePlayProgress:(NSTimer *)timer {
    NSDictionary *dict = [timer userInfo];
    NSIndexPath *indexPath = dict[@"indexPath"];
    UIButton *sender = dict[@"sender"];
    float timeLeft = self.player.currentTime/self.player.duration;
    HomeCell *cell = (HomeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.progressSlider setValue:timeLeft];
    
    if ([self.player isPlaying]) {
        NSLog(@"play");
    } else {
        NSLog(@"fin");
        [sliderTimer invalidate];
        [sender setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
}

- (IBAction)starDidChanged:(id)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    HomeCell *cell = (HomeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    PFObject *event = self.sampleData[indexPath.section][@"group"][indexPath.row];

    PFRelation *relation = [event relationForKey:@"Rate"];
    PFQuery *query = [relation query];
    [query whereKey:@"eventId" equalTo:event.objectId];
    [query whereKey:@"userId" equalTo:[PFUser currentUser].objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object) {
            [object setObject:[NSNumber numberWithFloat:cell.starRatingView.value] forKey:@"rate"];
            [object saveInBackground];
        } else {
            PFObject *rate = [PFObject objectWithClassName:@"Rate"];
            [rate setObject:[PFUser currentUser].objectId forKey:@"userId"];
            [rate setObject:[event objectForKey:@"fromUserId"] forKey:@"toUserId"];
            [rate setObject:[PFUser currentUser][@"surname"] forKey:@"surname"];
            [rate setObject:event.objectId forKey:@"eventId"];
            [rate setObject:[NSNumber numberWithFloat:cell.starRatingView.value] forKey:@"rate"];
            [rate saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    PFRelation *relation = [event relationForKey:@"Rate"];
                    [relation addObject:rate];
                    [event saveInBackground];
                }
            }];
        }
    }];
}

@end
