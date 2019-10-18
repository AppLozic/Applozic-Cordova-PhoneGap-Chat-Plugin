//
//  ALChatManager.m
//  applozicdemo
//
//  Created by Adarsh on 28/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ALChatManager.h"
#import <Applozic/ALUserDefaultsHandler.h>
#import <Applozic/ALMessageClientService.h>
#import <Applozic/ALApplozicSettings.h>
#import <Applozic/ALChatViewController.h>
#import <Applozic/ALMessage.h>
#import <Applozic/ALNewContactsViewController.h>


@implementation ALChatManager

-(instancetype)init {

    return [self initWithApplicationKey:[self getApplicationKey]];
}

-(instancetype)initWithApplicationKey:(NSString *)applicationKey;
{
    self = [super init];
    if (self)
    {
        [ALUserDefaultsHandler setApplicationKey:applicationKey];
        self.permissableVCList = [[NSArray alloc] init];
    }

    return self;
}

//==============================================================================================================================================
// Call This at time of your app's user authentication OR User registration.
// This will register your User at applozic server.
//==============================================================================================================================================

-(void)registerUser:(ALUser *)alUser
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];


    [self ALDefaultChatViewSettings];
    [alUser setApplicationId:[self getApplicationKey]];
    [alUser setAppModuleName:[ALUserDefaultsHandler getAppModuleName]];
    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService initWithCompletion:alUser withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {

        NSLog(@"USER_REGISTRATION_RESPONSE :: %@", rResponse);
        if(error)
        {
            NSLog(@"ERROR_USER_REGISTRATION :: %@",error);
            return;
        }

        if(![rResponse isRegisteredSuccessfully])
        {
            return;
        }

        if(rResponse && [rResponse.message containsString: @"REGISTERED"])
        {

        }
    }];
}

-(NSString *)getApplicationKey
{
    NSString * appKey = [ALUserDefaultsHandler getApplicationKey];
    NSLog(@"APPLICATION_KEY :: %@",appKey);
    return appKey ? appKey : APPLICATION_ID;
}

//==============================================================================================================================================
// Call This method if you want to do some operation on registration success.
// Example: If Chat is your first screen after launch,launch chat list on sucess of login.
//==============================================================================================================================================

-(void)registerUserWithCompletion:(ALUser *)alUser withHandler:(void(^)(ALRegistrationResponse *rResponse, NSError *error))completion
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];


    [self ALDefaultChatViewSettings];
    [alUser setApplicationId:[self getApplicationKey]];
    [alUser setAppModuleName:[ALUserDefaultsHandler getAppModuleName]];

    ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
    [registerUserClientService initWithCompletion:alUser withCompletion:^(ALRegistrationResponse *rResponse, NSError *error) {

        NSLog(@"USER_REGISTRATION_RESPONSE :: %@", rResponse);
        if(error)
        {
            NSLog(@"ERROR_USER_REGISTRATION :: %@",error.description);
            completion(nil, error);
            return;
        }

        if(![rResponse isRegisteredSuccessfully])
        {
            NSError *passError = [NSError errorWithDomain:rResponse.message code:0 userInfo:nil];
            completion(nil, passError);
            return;
        }

        completion(rResponse, error);
    }];
}

//==============================================================================================================================================
// convenient method to launch chat-list, after user registration is done on applozic server.
// This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
//==============================================================================================================================================

-(void)launchChat: (UIViewController *)fromViewController
{
    [self registerUserAndLaunchChat:nil andFromController:fromViewController forUser:nil withGroupId:nil];
}

//==============================================================================================================================================
// convenient method to directly launch individual user chat screen. UserId parameter define users for which it intented to launch chat screen.
// This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
//==============================================================================================================================================

-(void)launchChatForUserWithDefaultText:(NSString *)userId andFromViewController:(UIViewController *)fromViewController
{
    [self registerUserAndLaunchChat:nil andFromController:fromViewController forUser:userId withGroupId:nil];
}

//==============================================================================================================================================
// Method to register + lauch chats screen. If user is already registered, directly chats screen will be launched.
// If user information is not passed, it will try to get user information from getLoggedinUserInformation.
//==============================================================================================================================================

-(void)registerUserAndLaunchChat:(ALUser *)alUser andFromController:(UIViewController *)viewController forUser:(NSString *)userId
                     withGroupId:(NSNumber *)groupID
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];

    //User is already registered ..directly launch the chat...
    NSString * deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    NSLog(@"DEVICE_KEY : %@",deviceKey);
    if(deviceKey != nil)
    {
        if(userId)
        {
            [self.chatLauncher launchIndividualChat:userId withGroupId:groupID
                            andViewControllerObject:viewController andWithText:nil];
        }
        else
        {
            NSString * title = viewController.title? viewController.title: @"< Back";
            [self.chatLauncher launchChatList:title andViewControllerObject:viewController];
        }
        return;
    }

    //Registration Required....
    alUser = alUser ? alUser : [ALChatManager getLoggedinUserInformation];

    if(!alUser)
    {
        NSLog(@"Not able to find user detail for registration...please register with applozic server first");
        return;
    }

    [self registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

        if (!error)
        {
            if(userId)
            {
                [self.chatLauncher launchIndividualChat:userId
                                            withGroupId:groupID
                                andViewControllerObject:viewController
                                            andWithText:nil];
            }
            else
            {
                NSString * title = viewController.title? viewController.title: @"< Back";
                [self.chatLauncher launchChatList:title andViewControllerObject:viewController];
            }
        }
    }];
}

-(BOOL)isUserHaveMessages:(NSString *)userId
{
    ALMessageService * msgService = [ALMessageService new];
    NSUInteger count = [msgService getMessagsCountForUser:userId];
    NSLog(@"COUNT MESSAGES :: %lu",(unsigned long)count);
    return (count == 0);
}

//==============================================================================================================================================
// convenient method to directly launch individual user chat screen. UserId parameter define users for which it intented to launch chat screen.
// This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
//==============================================================================================================================================

-(void)launchChatForUserWithDisplayName:(NSString *)userId withGroupId:(NSNumber *)groupID andwithDisplayName:(NSString *)displayName
                  andFromViewController:(UIViewController *)fromViewController
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];

    BOOL flagForText = [self isUserHaveMessages:userId];
    NSString * preText = nil;
    if(flagForText)
    {
        preText = @""; // SET TEXT HERE
    }

    NSString * deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    NSLog(@"DEVICE_KEY : %@",deviceKey);
    if(deviceKey != nil)
    {
        [self.chatLauncher launchIndividualChat:userId withGroupId:groupID
                                withDisplayName:displayName
                        andViewControllerObject:fromViewController
                                    andWithText:preText];
        return;
    }

    ALUser *alUser = [ALChatManager getLoggedinUserInformation];
    [self registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

    }];
}

//==============================================================================================================================================
// Convenient method to directly launch individual context-based user chat screen.
// UserId parameter define users for which it intented to launch chat screen.
// This will automatically handle unregistered users provided getLoggedinUserInformation is implemented properly.
//==============================================================================================================================================

-(void)createAndLaunchChatWithSellerWithConversationProxy:(ALConversationProxy*)alConversationProxy
                                       fromViewController:(UIViewController*)fromViewController
{
    ALConversationService * alconversationService = [[ALConversationService alloc] init];
    [alconversationService  createConversation:alConversationProxy withCompletion:^(NSError *error,ALConversationProxy * proxyObject) {

        if(!error)
        {
            self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];
            NSString * deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
            NSLog(@"DEVICE_KEY : %@",deviceKey);
            if(deviceKey != nil)
            {
                ALConversationProxy * finalProxy = [self makeFinalProxyWithGeneratedProxy:alConversationProxy andFinalProxy:proxyObject];
                [self.chatLauncher launchIndividualContextChat:finalProxy andViewControllerObject:fromViewController userDisplayName:@"Adarsh" andWithText:nil];
            }
        }
    }];
}

//==============================================================================================================================================
// The below method combines the conversationID got from server's response with the details already set.
//==============================================================================================================================================

-(ALConversationProxy *)makeFinalProxyWithGeneratedProxy:(ALConversationProxy *)generatedProxy andFinalProxy:(ALConversationProxy *)responseProxy
{
    ALConversationProxy * finalProxy = [[ALConversationProxy alloc] init];
    finalProxy.userId = generatedProxy.userId;
    finalProxy.topicDetailJson = generatedProxy.topicDetailJson;
    finalProxy.Id = responseProxy.Id;
    finalProxy.groupId = responseProxy.groupId;
    return finalProxy;
}

//==============================================================================================================================================
// LAUNCH OPEN GROUP
//==============================================================================================================================================

-(void)launchOpenGroupWithKey:(NSNumber *)channelKey fromViewController:(UIViewController *)viewController
{
    ALChannelService *service = [ALChannelService new];
    [service getChannelInformation:channelKey orClientChannelKey:nil withCompletion:^(ALChannel *alChannel3) {

        [self launchChatForUserWithDisplayName:nil withGroupId:alChannel3.key andwithDisplayName:nil andFromViewController:viewController];
    }];
}


//============================================
// launching contact screen with message
//============================================

-(void)launchContactScreenWithMessage:(ALMessage *)alMessage andFromViewController:(UIViewController *)viewController
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Applozic" bundle:[NSBundle bundleForClass:ALChatViewController.class]];
    ALNewContactsViewController *contactVC = (ALNewContactsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ALNewContactsViewController"];
    contactVC.directContactVCLaunch = YES;
    contactVC.alMessage = alMessage;
    UINavigationController *conversationViewNavController = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [viewController presentViewController:conversationViewNavController animated:YES completion:nil];
}

//==============================================================================================================================================
// This method can be used to get app logged-in user's information.
// If user information is stored in DB or preference, Code to get user's information should go here.
// This might be used to get existing user information in case of app update.
//==============================================================================================================================================

+(ALUser *)getLoggedinUserInformation
{
    ALUser *user = [[ALUser alloc] init];

    [user setApplicationId:[[[self alloc] init] getApplicationKey]];
    [user setAppModuleName:[ALUserDefaultsHandler getAppModuleName]];      // 3. APP_MODULE_NAME setter

    [user setUserId:[ALUserDefaultsHandler getUserId]];
    [user setEmail:[ALUserDefaultsHandler getEmailId]];
    [user setPassword:[ALUserDefaultsHandler getPassword]];
    [user setDisplayName:[ALUserDefaultsHandler getDisplayName]]; // IF SETTING ANY DISPLAY NAME THEN UNCOMMENT IT

    return user;
}

//==============================================================================================================================================
// This method helps you customise various settings
//==============================================================================================================================================

-(void)ALDefaultChatViewSettings
{

    /*********************************************  NAVIGATION SETTINGS  ********************************************/

    [ALApplozicSettings setStatusBarBGColor:[UIColor colorWithRed:66.0/255 green:173.0/255 blue:247.0/255 alpha:1]];
    [ALApplozicSettings setStatusBarStyle:UIStatusBarStyleLightContent];
    /* BY DEFAULT Black:UIStatusBarStyleDefault IF REQ. White: UIStatusBarStyleLightContent  */
    /* ADD property in info.plist "View controller-based status bar appearance" type: BOOLEAN value: NO */

    [ALApplozicSettings setColorForNavigation:[UIColor colorWithRed:66.0/255 green:173.0/255 blue:247.0/255 alpha:1]];
    [ALApplozicSettings setColorForNavigationItem:[UIColor whiteColor]];
    [ALApplozicSettings hideRefreshButton:NO];
    [ALUserDefaultsHandler setNavigationRightButtonHidden:NO];
    [ALUserDefaultsHandler setBottomTabBarHidden:YES];
    [ALApplozicSettings setTitleForConversationScreen:@"Chats"];
    [ALApplozicSettings setTitleForBackButtonMsgVC:@"Back"];                /*  SET BACK BUTTON FOR MSG VC  */
    [ALApplozicSettings setTitleForBackButtonChatVC:@"Back"];               /*  SET BACK BUTTON FOR CHAT VC */
    [ALApplozicSettings setDropShadowInNavigationBar:YES];                    /*  ENABLE / DISABLE DROPS IN SHADOW IN NAVIGATION BAR */
    /****************************************************************************************************************/

    //Font size for cells
    [ALApplozicSettings setChatCellTextFontSize:15];

    [ALApplozicSettings setChannelCellTextFontSize:15];


    /***************************************  SEND RECEIVE MESSAGES SETTINGS  ***************************************/
    [ALApplozicSettings showChannelMembersInfoInNavigationBar:YES];
    [ALApplozicSettings setSendMsgTextColor:[UIColor whiteColor]];
    [ALApplozicSettings setReceiveMsgTextColor:[UIColor grayColor]];
    [ALApplozicSettings setColorForReceiveMessages:[UIColor colorWithRed:255/255 green:255/255 blue:255/255 alpha:1]];
    [ALApplozicSettings setColorForSendMessages:[UIColor colorWithRed:66.0/255 green:173.0/255 blue:247.0/255 alpha:1]];

    [ALApplozicSettings setCustomMessageBackgroundColor:[UIColor lightGrayColor]];              /*  SET CUSTOM MESSAGE COLOR */
    [ALApplozicSettings setCustomMessageFontSize:14];                                     /*  SET CUSTOM MESSAGE FONT SIZE */
    [ALApplozicSettings setCustomMessageFont:@"Helvetica"];


//    [ALApplozicSettings setChatCellFontTextStyle:UIFontTextStyleSubheadline];
//    [ALApplozicSettings setChatChannelCellFontTextStyle:UIFontTextStyleSubheadline];

    //****************** DATE COLOUR : AT THE BOTTOM OF MESSAGE BUBBLE ******************/
    [ALApplozicSettings setDateColor:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:0.5]];

    //****************** MESSAGE SEPERATE DATE COLOUR : DATE MESSAGE ******************/
    [ALApplozicSettings setMsgDateColor:[UIColor blackColor]];

    /***************  SEND MESSAGE ABUSE CHECK  ******************/

    [ALApplozicSettings setAbuseWarningText:@"AVOID USE OF ABUSE WORDS"];
    [ALApplozicSettings setMessageAbuseMode:YES];

    //****************** SHOW/HIDE RECEIVER USER PROFILE ******************/
    [ALApplozicSettings setReceiverUserProfileOption:NO];

    /****************************************************************************************************************/


    /**********************************************  IMAGE SETTINGS  ************************************************/

    [ALApplozicSettings setMaxCompressionFactor:0.1f];
    [ALApplozicSettings setMaxImageSizeForUploadInMB:3];
    [ALApplozicSettings setMultipleAttachmentMaxLimit:5];
    /****************************************************************************************************************/


    /**********************************************  GROUP SETTINGS  ************************************************/

    [ALApplozicSettings setGroupOption:YES];
    [ALApplozicSettings setGroupInfoDisabled:NO];
    [ALApplozicSettings setGroupInfoEditDisabled:NO];


    [ALApplozicSettings setGroupExitOption:YES];
    [ALApplozicSettings setGroupMemberAddOption:YES];
    [ALApplozicSettings setGroupMemberRemoveOption:YES];


    /****************************************************************************************************************/


    /******************************************** NOTIIFCATION SETTINGS  ********************************************/


    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    [ALApplozicSettings setNotificationTitle:appName];

        [ALApplozicSettings enableNotification]; //0
    //    [ALApplozicSettings disableNotification]; //2
    //    [ALApplozicSettings disableNotificationSound]; //1                /*  IF NOTIFICATION SOUND NOT NEEDED  */
    //    [ALApplozicSettings enableNotificationSound];//0                   /*  IF NOTIFICATION SOUND NEEDED    */
    /****************************************************************************************************************/


    /********************************************* CHAT VIEW SETTINGS  **********************************************/

    [ALApplozicSettings setVisibilityForNoMoreConversationMsgVC:NO];        /*  SET VISIBILITY NO MORE CONVERSATION (COMES FROM TOP IN MSG VC)  */
    [ALApplozicSettings setEmptyConversationText:@"You have no conversations yet"]; /*  SET TEXT FOR EMPTY CONVERSATION    */
    [ALApplozicSettings setVisibilityForOnlineIndicator:YES];               /*  SET VISIBILITY FOR ONLINE INDICATOR */
    UIColor * sendButtonColor = [UIColor colorWithRed:66.0/255 green:173.0/255 blue:247.0/255 alpha:1]; /*  SET COLOR FOR SEND BUTTON   */
    [ALApplozicSettings setColorForSendButton:sendButtonColor];
    [ALApplozicSettings setColorForTypeMsgBackground:[UIColor clearColor]];     /*  SET COLOR FOR TYPE MESSAGE OUTER VIEW */
    [ALApplozicSettings setMsgTextViewBGColor:[UIColor lightGrayColor]];        /*  SET BG COLOR FOR MESSAGE TEXT VIEW */
    [ALApplozicSettings setPlaceHolderColor:[UIColor grayColor]];               /*  SET COLOR FOR PLACEHOLDER TEXT */
    [ALApplozicSettings setVisibilityNoConversationLabelChatVC:YES];            /*  SET NO CONVERSATION LABEL IN CHAT VC    */
    [ALApplozicSettings setBGColorForTypingLabel:[UIColor colorWithRed:242/255.0 green:242/255.0  blue:242/255.0 alpha:1]]; /*  SET COLOR FOR TYPING LABEL  */
    [ALApplozicSettings setTextColorForTypingLabel:[UIColor colorWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:0.5]]; /*  SET COLOR FOR TEXT TYPING LABEL  */
    /****************************************************************************************************************/


    /********************************************** CHAT TYPE SETTINGS  *********************************************/

    [ALApplozicSettings setContextualChat:YES];                                 /*  IF CONTEXTUAL NEEDED    */
    /*  Note: Please uncomment below setter to use app_module_name */
    //   [ALUserDefaultsHandler setAppModuleName:@"<APP_MODULE_NAME>"];
    //   [ALUserDefaultsHandler setAppModuleName:@"SELLER"];
    /****************************************************************************************************************/


    /*********************************************** CONTACT SETTINGS  **********************************************/

    [ALApplozicSettings setFilterContactsStatus:YES];                           /*  IF NEEDED ALL REGISTERED CONTACTS   */
    [ALApplozicSettings setOnlineContactLimit:0];                               /*  IF NEEDED ONLINE USERS WITH LIMIT   */

    [ALApplozicSettings setSubGroupLaunchFlag:NO];                             /*  IF NEEDED ONLINE USERS WITH LIMIT   */
    /****************************************************************************************************************/


    /***************************************** TOAST + CALL OPTION SETTINGS  ****************************************/

    [ALApplozicSettings setColorForToastText:[UIColor blackColor]];         /*  SET COLOR FOR TOAST TEXT    */
    [ALApplozicSettings setColorForToastBackground:[UIColor grayColor]];    /*  SET COLOR FOR TOAST BG      */
    [ALApplozicSettings setCallOption:YES];                                 /*  IF CALL OPTION NEEDED   */
    /****************************************************************************************************************/


    /********************************************* DEMAND/MISC SETTINGS  ********************************************/

    [ALApplozicSettings setUnreadCountLabelBGColor:[UIColor purpleColor]];
    [ALApplozicSettings setCustomClassName:@"ALChatManager"];                   /*  SET 3rd Party Class Name OR ALChatManager */
    [ALUserDefaultsHandler setFetchConversationPageSize:60];                    /*  SET MESSAGE LIST PAGE SIZE  */ // DEFAULT VALUE 20
    [ALUserDefaultsHandler setUnreadCountType:1];                               /*  SET UNRAED COUNT TYPE   */ // DEFAULT VALUE 0
    [ALApplozicSettings setMaxTextViewLines:4];
    [ALUserDefaultsHandler setDebugLogsRequire:YES];                            /*   ENABLE / DISABLE LOGS   */
    [ALUserDefaultsHandler setLoginUserConatactVisibility:NO];
    [ALApplozicSettings setUserProfileHidden:NO];
    [ALApplozicSettings setFontFace:@"Helvetica"];
    [ALApplozicSettings setChatWallpaperImageName:@"<WALLPAPER NAME>"];
    [ALApplozicSettings replyOptionEnabled:YES];
    [ALApplozicSettings forwardOptionEnableOrDisable:YES];


    /****************************************************************************************************************/


    /***************************************** APPLICATION URL CONFIGURATION + ENCRYPTION  ***************************************/

    //    [self getApplicationBaseURL];                                         /* Note: PLEASE DO NOT COMMENT THIS IF ARCHIVING/RELEASING  */

    [ALUserDefaultsHandler setEnableEncryption:NO];                            /* Note: PLEASE DO YES (IF NEEDED)  */
    /****************************************************************************************************************/

    [ALUserDefaultsHandler setGoogleMapAPIKey:@"AIzaSyBnWMTGs1uTFuf8fqQtsmLk-vsWM7OrIXk"]; //REPLACE WITH YOUR GOOGLE MAPKEY

//    NSMutableArray * array = [NSMutableArray new];
//    [array addObject:[NSNumber numberWithInt:1]];
//    [array addObject:[NSNumber numberWithInt:2]];
//
//    [ALApplozicSettings setContactTypeToFilter: array];         // SET ARRAY TO PREFERENCE

    /************************************** 3rd PARTY VIEWS + MSg CONTAINER SETTINGS  *************************************/

//    NSArray * viewArray = @[@"VC1", @"VC2"];    // VC : ViewController's Class Name
//    [self.permissableVCList arrayByAddingObject:@""];

//    [ALApplozicSettings setMsgContainerVC:@""];  // ADD CLASS NAME
    /**********************************************************************************************************************/

    [ALApplozicSettings setUserDeletedText:@"User has been deleted"];            /*  SET DELETED USER NOTIFICATION TITLE   */


    /******************************************** CUSTOM TAB BAR ITEM : ICON && TEXT ************************************************/
    [ALApplozicSettings setChatListTabIcon:@""];
    [ALApplozicSettings setProfileTabIcon:@""];

    [ALApplozicSettings setChatListTabTitle:@""];
    [ALApplozicSettings setProfileTabTitle:@""];
    // Hide attachment options in chat screen
//    NSArray * attachmentOptionToHide = @[@":audio", @":video", @":location",@":shareContact"];
//
//    [ALApplozicSettings setHideAttachmentsOption:attachmentOptionToHide];

    /********************************************* Attachment Plus Icon background color
     *****************************************************************/
    [ALApplozicSettings setBackgroundColorForAttachmentPlusIcon:[UIColor colorWithRed:0.0/255 green:0.0/255 blue:0.0/255 alpha:1]];

    //Audio Recording View color
    [ALApplozicSettings enableNewAudioDesign:YES];
    [ALApplozicSettings setBackgroundColorForAudioRecordingView:[UIColor lightGrayColor]];
    [ALApplozicSettings setColorForAudioRecordingText:[UIColor redColor]];
    [ALApplozicSettings setColorForSlideToCancelText:[UIColor darkGrayColor]];
    [ALApplozicSettings setFontForAudioView:@"HelveticaNeue"];
}

-(void)getApplicationBaseURL
{
    NSDictionary * URLDictionary = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"APPLOZIC_PRODUCTION"];

    NSString * alKBASE_URL = [URLDictionary valueForKey:@"AL_KBASE_URL"];
    NSString * alMQTT_URL = [URLDictionary valueForKey:@"AL_MQTT_URL"];
    NSString * alFILE_URL = [URLDictionary valueForKey:@"AL_FILE_URL"];
    NSString * alMQTT_PORT = [URLDictionary valueForKey:@"AL_MQTT_PORT"];

    [ALUserDefaultsHandler setBASEURL:alKBASE_URL];
    [ALUserDefaultsHandler setMQTTURL:alMQTT_URL];
    [ALUserDefaultsHandler setFILEURL:alFILE_URL];
    [ALUserDefaultsHandler setMQTTPort:alMQTT_PORT];
}

//==============================================================================================================================================
// Launch chat list with specified User's chat screen open
//==============================================================================================================================================

-(void)launchListWithUserORGroup:(NSString *)userId ORWithGroupID:(NSNumber *)groupId andFromViewController:(UIViewController*)fromViewController
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];

    //User is already registered ..directly launch the chat...
    NSString * deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    NSLog(@"DEVICE_KEY : %@",deviceKey);
    if(deviceKey != nil)
    {
        //Launch
        if(userId || groupId)
        {
            [self.chatLauncher launchChatListWithUserOrGroup:userId withChannel:groupId
                                     andViewControllerObject:fromViewController];
        }
        else
        {
            NSString * title = fromViewController.title? fromViewController.title: @"< Back";
            [self.chatLauncher launchChatList:title andViewControllerObject:fromViewController];
        }
        return;
    }

    //Registration Reuired....
    ALUser *alUser = [ALChatManager getLoggedinUserInformation];

    if(!alUser)
    {
        NSLog(@"Not able to find user detail for registration...please register with applozic server first");
        return;
    }

    [self registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

        if (!error)
        {
            if(userId || groupId)
            {
                [self.chatLauncher launchChatListWithUserOrGroup:userId
                                                     withChannel:groupId
                                         andViewControllerObject:fromViewController];
            }
            else
            {
                NSString * title = fromViewController.title? fromViewController.title: @"< Back";
                [self.chatLauncher launchChatList:title andViewControllerObject:fromViewController];
            }
        }
    }];
}

//==============================================================================================================================================
#pragma mark : LAUNCH SUB GROUP MESSAGE LIST
//==============================================================================================================================================

-(void)launchChatListWithParentKey:(NSNumber *)parentGroupKey andFromViewController:(UIViewController *)viewController
{
    self.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];
    NSString * deviceKey = [ALUserDefaultsHandler getDeviceKeyString];
    NSLog(@"DEVICE_KEY : %@",deviceKey);
    if(deviceKey != nil)
    {
        [self.chatLauncher launchChatListWithParentKey:parentGroupKey andViewControllerObject:viewController];
        return;
    }

    [self ALDefaultChatViewSettings];
    ALUser *alUser = [ALChatManager getLoggedinUserInformation];
    [self registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

       if (!error)
       {
           [self.chatLauncher launchChatListWithParentKey:parentGroupKey
                                  andViewControllerObject:viewController];
       }
    }];
}

//==============================================================================================================================================
// DELEGATE FOR THIRD PARTY ACTION ON TAP GESTURE
//==============================================================================================================================================

+(void)handleCustomAction:(UIViewController *)chatView andWithMessage:(ALMessage *)alMessage
{
    NSLog(@"DELEGATE FOR THIRD PARTY ACTION ON TAP GESTURE");
    NSLog(@"ALMESSAGE_META_DATA :: %@", alMessage.metadata);
    //    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //    UIViewController * customView = [storyboard instantiateViewControllerWithIdentifier:@"CustomVC"];
    //    ALChatViewController * chatVC = (ALChatViewController *)chatView;
    //    [chatVC presentViewController:customView animated:YES completion:nil];
}

@end
