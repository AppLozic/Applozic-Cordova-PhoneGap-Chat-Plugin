//
//  ALChatManager.m
//  applozicdemo
//
//  Created by Adarsh on 28/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ApplozicCordovaPlugin.h"
#import "ALChatManager.h"
#import <Applozic/ALUserDefaultsHandler.h>
#import <Applozic/ALMessageClientService.h>
#import <Applozic/ALApplozicSettings.h>
#import <Applozic/ALChatViewController.h>
#import <Applozic/ALMessage.h>
#import <Applozic/ALNewContactsViewController.h>
#import <Applozic/ALPushAssist.h>
#import <Applozic/ALContactService.h>
#import <Applozic/ALChannelService.h>
#import <Applozic/ALUserService.h>
#import <Applozic/ALChannelDBService.h>
#import <Applozic/AlChannelFeedResponse.h>
#import <Applozic/AlChannelInfoModel.h>
#import <Applozic/AlChannelResponse.h>
#import <Applozic/ApplozicClient.h>
#import <Applozic/AlChannelResponse.h>
#import <Applozic/ALNotificationHelper.h>
#import <Applozic/ALMessageDBService.h>

@implementation ApplozicCordovaPlugin

-(NSString *)getApplicationKey
{
    NSString * appKey = [ALUserDefaultsHandler getApplicationKey];
    NSLog(@"APPLICATION_KEY :: %@",appKey);
    return appKey ? appKey : APPLICATION_ID;
}

- (ALChatManager *)getALChatManager:(NSString*)applicationId
{
    if (!applicationId) {
        applicationId = [self getApplicationKey];
    }
    return [[ALChatManager alloc] initWithApplicationKey:applicationId];
}

- (void)login:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    ALUser * alUser = [[ALUser alloc] initWithJSONString:jsonStr];
    [ALUserDefaultsHandler setUserAuthenticationTypeId:alUser.authenticationTypeId];
    ALChatManager *alChatManager = [self getALChatManager:alUser.applicationId];
    [alChatManager registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {

        CDVPluginResult* result;

        if (!error) {

            NSError * error;
            NSData * postdata = [NSJSONSerialization dataWithJSONObject:rResponse.dictionary options:0 error:&error];

            NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];

            result  = [CDVPluginResult
                       resultWithStatus:CDVCommandStatus_OK
                       messageAsString:jsonString];
        } else {
            result =  [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];

        }

        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void) isLoggedIn:(CDVInvokedUrlCommand*)command
{
    NSString* response = @"false";
    if ([ALUserDefaultsHandler isLoggedIn]) {
        response = @"true";
    }

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:response];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) updatePushNotificationToken:(CDVInvokedUrlCommand*)command
{
    NSString* apnDeviceToken = [[command arguments] objectAtIndex:0];
    if (apnDeviceToken) {
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService updateApnDeviceTokenWithCompletion:apnDeviceToken
                                                       withCompletion:^(ALRegistrationResponse*rResponse, NSError *error) {
            if (error) {
                NSLog(@"%@",error);
                return;
            }
            NSLog(@"Registration response from server:%@", rResponse);
        }];
    }
}

/*
 -(void) processPushNotification:(CDVInvokedUrlCommand*)command {
 //Todo: create dictionary from command
 ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
 [pushNotificationService notificationArrivedToApplication:application withDictionary:dictionary];
 }

 -(void) processBackgrou dPushNotification:(CDVInvokedUrlCommand*)command {
 {
 NSLog(@"Received notification Completion: %@", userInfo);
 ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
 [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
 completionHandler(UIBackgroundFetchResultNewData);
 }
 */

- (void) launchChat:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];

    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    [alChatManager launchChat:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) launchChatWithUserId:(CDVInvokedUrlCommand*)command
{
    NSString* userId = [[command arguments] objectAtIndex:0];

    [self verifyTopVCAndLaunchChatWithUserId:userId withGroupId:nil];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                messageAsString:@"success"];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) launchChatWithGroupId:(CDVInvokedUrlCommand*)command
{
    NSString * groupIdStr = [[command arguments] objectAtIndex:0];
    NSNumber *groupId = [NSNumber numberWithInt:[groupIdStr intValue]];

    ALChannelService * channelService = [[ALChannelService alloc] init];
    [channelService getChannelInformation:groupId orClientChannelKey:nil withCompletion:^(ALChannel *alChannel) {
        CDVPluginResult* result;
        if (alChannel) {
            [self verifyTopVCAndLaunchChatWithUserId:nil withGroupId:alChannel.key];

            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                       messageAsString:@"success"];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"error"];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }];
}

- (void) launchChatWithClientGroupId:(CDVInvokedUrlCommand*)command
{
    NSString* clientGroupId = [[command arguments] objectAtIndex:0];
    ALChannelService * channelService = [[ALChannelService alloc] init];

    [channelService getChannelInformation:nil orClientChannelKey:clientGroupId withCompletion:^(ALChannel *alChannel) {
        CDVPluginResult* result;

        if (alChannel) {
            [self verifyTopVCAndLaunchChatWithUserId:nil withGroupId:alChannel.key];
            result = [CDVPluginResult
                      resultWithStatus:CDVCommandStatus_OK
                      messageAsString:@"success"];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"error"];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }];

}

-(void)getGroupInfoWithGroupId:(CDVInvokedUrlCommand*)command{

    NSNumber* groupId = [[command arguments] objectAtIndex:0];

    ALChannelService * channelService = [[ALChannelService alloc] init];
    [channelService getChannelInformationByResponse:groupId orClientChannelKey:nil withCompletion:^(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse) {

        CDVPluginResult* result;

        if(alChannel){

            AlChannelInfoModel *alChannelInfoModel= [[AlChannelInfoModel alloc]init];
            AlChannelResponse * alChannelResponse = [[AlChannelResponse alloc ] init];

            ALChannelService * channelService = [[ALChannelService alloc] init];
            alChannelResponse.key = alChannel.key;
            alChannelResponse.imageUrl = alChannel.channelImageURL;
            alChannelResponse.name = alChannel.name;
            alChannelResponse.notificationAfterTime = alChannel.notificationAfterTime;
            alChannelResponse.deletedAtTime = alChannel.deletedAtTime;
            alChannelResponse.clientGroupId = alChannel.clientChannelKey;
            alChannelResponse.type = alChannel.type;
            alChannelResponse.adminKey = alChannel.adminKey;
            alChannelResponse.userCount = alChannel.userCount;
            alChannelResponse.unreadCount = alChannel.unreadCount;
            alChannelResponse.conversationProxy = alChannel.conversationProxy;
            alChannelResponse.metadata = alChannel.metadata;
            if(!alChannel.membersId){
                alChannel.membersId =  [channelService getListOfAllUsersInChannel:alChannel.key];
            }
            alChannelInfoModel.groupMemberList = alChannel.membersId;
            alChannelInfoModel.channel = alChannelResponse.dictionary;

            NSError * nsError;
            NSData * postdata = [NSJSONSerialization dataWithJSONObject:alChannelInfoModel.dictionary options:0 error:&nsError];
            NSString *json = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];

            result = [CDVPluginResult
                      resultWithStatus:CDVCommandStatus_OK
                      messageAsString:json];
        }else if(channelResponse != nil && [channelResponse.status isEqualToString:@"error"]){

            NSError *writeError = nil;
            NSArray * errorArray = [channelResponse.actualresponse valueForKey:@"errorResponse"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[errorArray objectAtIndex:0] options:NSJSONWritingPrettyPrinted error:&writeError];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];

            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:jsonString];
        }else{
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }


        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }];

}


-(void)getGroupInfoWithClientGroupId:(CDVInvokedUrlCommand*)command{

    NSString* clientGroupId = [[command arguments] objectAtIndex:0];

    ALChannelService * channelService = [[ALChannelService alloc] init];
    [channelService getChannelInformationByResponse:nil orClientChannelKey:clientGroupId withCompletion:^(NSError *error, ALChannel *alChannel, AlChannelFeedResponse *channelResponse) {

        CDVPluginResult* result;
        if(alChannel){

            AlChannelInfoModel *alChannelInfoModel= [[AlChannelInfoModel alloc]init];
            AlChannelResponse * alChannelResponse = [[AlChannelResponse alloc ] init];

            ALChannelService * channelService = [[ALChannelService alloc] init];
            alChannelResponse.key = alChannel.key;
            alChannelResponse.imageUrl = alChannel.channelImageURL;
            alChannelResponse.name = alChannel.name;
            alChannelResponse.notificationAfterTime = alChannel.notificationAfterTime;
            alChannelResponse.deletedAtTime = alChannel.deletedAtTime;
            alChannelResponse.clientGroupId = alChannel.clientChannelKey;
            alChannelResponse.type = alChannel.type;
            alChannelResponse.adminKey = alChannel.adminKey;
            alChannelResponse.userCount = alChannel.userCount;
            alChannelResponse.unreadCount = alChannel.unreadCount;
            alChannelResponse.conversationProxy = alChannel.conversationProxy;
            alChannelResponse.metadata = alChannel.metadata;
            if(!alChannel.membersId){
                alChannel.membersId =  [channelService getListOfAllUsersInChannel:alChannel.key];
            }
            alChannelInfoModel.groupMemberList = alChannel.membersId;
            alChannelInfoModel.channel = alChannelResponse.dictionary;

            NSError * nsError;
            NSData * postdata = [NSJSONSerialization dataWithJSONObject:alChannelInfoModel.dictionary options:0 error:&nsError];
            NSString *json = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];

            result = [CDVPluginResult
                      resultWithStatus:CDVCommandStatus_OK
                      messageAsString:json];
        }else if(channelResponse != nil && [channelResponse.status isEqualToString:@"error"]){

            NSError *writeError = nil;
            NSArray * errorArray = [channelResponse.actualresponse valueForKey:@"errorResponse"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[errorArray objectAtIndex:0] options:NSJSONWritingPrettyPrinted error:&writeError];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];

            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:jsonString];
        }else{
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }

        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }];

}

-(void)startNewConversation:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    alChatManager.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];
    ALPushAssist * assitant = [[ALPushAssist alloc] init];

    [alChatManager.chatLauncher launchContactList:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) showAllRegisteredUsers:(CDVInvokedUrlCommand*)command
{
    NSString* showAll = [[command arguments] objectAtIndex:0];
    [ALApplozicSettings setFilterContactsStatus:[showAll boolValue]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) addContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];
    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService addContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) updateContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];
    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService updateContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) removeContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];

    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService purgeContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) addContacts:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    NSError* error;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", jsonObject);
    NSLog(@"%@", error);
    NSArray * jsonArray = [NSArray arrayWithArray:(NSArray *)jsonObject];
    if(jsonArray.count)
    {
        NSDictionary * JSONDictionary = (NSDictionary *)jsonObject;
        ALContactService * alContactService = [[ALContactService alloc] init];
        for (NSDictionary * theDictionary in JSONDictionary)
        {
            ALContact * userDetail = [[ALContact alloc] initWithDict:theDictionary];
            [alContactService updateOrInsert:userDetail];
            NSLog(@" userDetail ::%@",userDetail.displayName);
        }
    }

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) createGroup:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];

    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    ALChannel *alChannel = [[ALChannel alloc] init];

    if([jsonObject objectForKey:@"groupName"] != nil){
        [alChannel setName:[jsonObject objectForKey:@"groupName"]];
    }
    if([jsonObject objectForKey:@"imageUrl"] != nil){
        [alChannel setChannelImageURL:[jsonObject objectForKey:@"imageUrl"]];
    }
    if([jsonObject objectForKey:@"clientGroupId"] != nil){
        [alChannel setClientChannelKey:[jsonObject objectForKey:@"clientGroupId"]];
    }
    if([jsonObject objectForKey:@"groupMemberList"] != nil){
        [alChannel setMembersId:[jsonObject objectForKey:@"groupMemberList"]];
    }
    if([jsonObject objectForKey:@"metadata"] != nil){
        [alChannel setMetadata:[jsonObject objectForKey:@"metadata"]];
    }
    if([jsonObject objectForKey:@"type"] != nil){
        [alChannel setType:[[jsonObject objectForKey:@"type"] shortValue]];
    }
    if([jsonObject objectForKey:@"admin"] != nil){
        [alChannel setAdminKey:[jsonObject objectForKey:@"admin"]];
    }
    if(alChannel.membersId == nil){
        [alChannel setMembersId:[[NSMutableArray alloc] init]];
    }
    if([jsonObject objectForKey:@"users"] != nil){
        NSMutableArray *groupUserArrayJSON = [jsonObject objectForKey:@"users"];
        NSMutableArray *groupUsers = [[NSMutableArray alloc] init];
        for (int i=0; i<groupUserArrayJSON.count; i++) {
            ALGroupUser* groupUser = groupUserArrayJSON[i];
            [groupUsers addObject:groupUser];
        }
        alChannel.groupUsers = groupUsers;
    }

    [alChannelService createChannel:alChannel.name orClientChannelKey:alChannel.clientChannelKey andMembersList:alChannel.membersId andImageLink:alChannel.channelImageURL channelType:alChannel.type andMetaData:alChannel.metadata adminUser:alChannel.adminKey withGroupUsers:alChannel.groupUsers  withCompletion:^(ALChannel *alChannel, NSError *error) {

        if(error == nil){
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK
                                       messageAsString:alChannel.key.stringValue];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }else {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:error.description];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }];
}


- (void) addGroupMember:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", error);

    NSString *userId = [jsonObject objectForKey:@"userId"];
    NSNumber *channelKey = [jsonObject objectForKey:@"groupId"];


    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    [alChannelService addMemberToChannel:userId andChannelKey:channelKey orClientChannelKey:nil
                          withCompletion:^(NSError *error, ALAPIResponse *response) {
        CDVPluginResult* result ;
        if(!error && [response.status isEqualToString:@"success"])
        {
            result = [CDVPluginResult
                      resultWithStatus:CDVCommandStatus_OK
                      messageAsString:response.status];

        }else if(response != nil && [response.status isEqualToString:@"error"]){

            NSError *writeError = nil;
            NSArray * errorArray = [response.actualresponse valueForKey:@"errorResponse"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[errorArray objectAtIndex:0] options:NSJSONWritingPrettyPrinted error:&writeError];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];
            NSLog(@"JSON Output: %@", jsonString);

            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:jsonString];
        }else{
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        }

        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }];

}


- (void) removeGroupMember:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];

    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", error);

    NSString *userId = [jsonObject objectForKey:@"userId"];
    NSNumber *channelKey = [jsonObject objectForKey:@"groupId"];

    ALChannelService *alChannelService = [[ALChannelService alloc]init];

    [alChannelService removeMemberFromChannel:userId andChannelKey:channelKey orClientChannelKey:nil withCompletion:^(NSError *error, ALAPIResponse *response) {

        CDVPluginResult* result ;
        if(!error && [response.status isEqualToString:@"success"])
        {
            result =  [CDVPluginResult
                       resultWithStatus:CDVCommandStatus_OK
                       messageAsString:response.status];

        }else if(response != nil && [response.status isEqualToString:@"error"]){

            NSError *writeError = nil;
            NSArray * errorArray = [response.actualresponse valueForKey:@"errorResponse"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[errorArray objectAtIndex:0] options:NSJSONWritingPrettyPrinted error:&writeError];
            NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];
            NSLog(@"JSON Output: %@", jsonString);

            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
        }else{
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        }

        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];

}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    ALRegisterUserClientService * alUserClientService = [[ALRegisterUserClientService alloc]init];
    if([ALUserDefaultsHandler getDeviceKeyString]) {
        [alUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK
                                       messageAsString:@"success"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }];
    }
}

- (void) getUnreadCount:(CDVInvokedUrlCommand*)command
{

    ALUserService * alUserService = [[ALUserService alloc] init];
  if (![ALUserDefaultsHandler isInitialMessageListCallDone]) {
      ALMessageDBService * messageDBService = [[ALMessageDBService alloc] init];
      [messageDBService getLatestMessages:NO
                    withCompletionHandler:^(NSMutableArray *messageListArray, NSError *error) {
          CDVPluginResult* result;
          if (error) {
              result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to fetch the unread count"];
          } else {
              NSNumber * totalUnreadCount = [alUserService getTotalUnreadCount];
              result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                         messageAsString:[totalUnreadCount stringValue]];
          }
          [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      }];
  } else {
      NSNumber * totalUnreadCount = [alUserService getTotalUnreadCount];
      CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsString:[totalUnreadCount stringValue]];
      [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
  }
}

- (void) getUnreadCountForGroup:(CDVInvokedUrlCommand*)command
{
    NSNumber* channelKey = [[command arguments] objectAtIndex:0];

    ALChannelService *channelService = [ALChannelService new];
    ALChannel *alChannel = [channelService getChannelByKey:channelKey];
    NSNumber *unreadCount = [alChannel unreadCount];


    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[unreadCount stringValue]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

}

- (void) getUnreadCountForUser:(CDVInvokedUrlCommand*)command
{
    NSString* userId = [[command arguments] objectAtIndex:0];

    ALContactService* contactService = [ALContactService new];
    ALContact *contact = [contactService loadContactByKey:@"userId" value:userId];
    NSNumber *unreadCount = [contact unreadCount];

    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[unreadCount stringValue] ];

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

}

-(void)startTopicBasedChat:(CDVInvokedUrlCommand *)command
{
    NSString *jsonString = [[command arguments] objectAtIndex:0];
    if ([jsonString rangeOfString:@"topicDetail"].location != NSNotFound) {
        jsonString = [jsonString stringByReplacingOccurrencesOfString:@"topicDetail" withString:@"topicDetailJson"];
    }
    ALConversationProxy * conversationProxy = [[ALConversationProxy alloc] initWithJSONString:jsonString];

    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    [alChatManager createAndLaunchChatWithSellerWithConversationProxy:conversationProxy fromViewController:[assitant topViewController]];
}

-(void)verifyTopVCAndLaunchChatWithUserId:(NSString *)userId withGroupId:(NSNumber *)groupId {

    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];

    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    ALNotificationHelper * notificationHelper = [[ALNotificationHelper alloc] init];

    if ([notificationHelper isApplozicViewControllerOnTop]) {
        [notificationHelper handlerNotificationClick:userId withGroupId:groupId withConversationId:nil notificationTapActionDisable:false];
    } else {
        [alChatManager launchChatForUserWithDisplayName:userId
                                            withGroupId:groupId //If launched for group, pass groupId(pass userId as nil)
                                     andwithDisplayName:nil //Not mandatory, if receiver is not already registered you should pass Displayname.
                                  andFromViewController:[assitant topViewController]];
    }

}

@end
