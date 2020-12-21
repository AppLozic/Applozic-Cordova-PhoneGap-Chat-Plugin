# Applozic Cordova Chat Plugin for Ionic and PhoneGap

Applozic powers real time messaging across any device, any platform & anywhere in the world. Integrate our simple SDK to engage your users with image, file, location sharing and audio/video conversations.

Signup at https://www.applozic.com/signup.html to get the App ID.

## Note

This plugin is a wrapper around native code, so please make sure you test it on an emulator or a real device. This plugin wont work with browser or ionic lab. This plugin will only work on Android and iOS platforms. If you are looking for a javascript specific plugin you can explore our following repos :

 Web Plugin - https://github.com/AppLozic/Applozic-Web-Plugin
 Phonegap Plugin - https://github.com/AppLozic/Applozic-PhoneGap-Chat-Plugin

## Prerequisites

### iOS
* Apps must target iOS 10 or later
* Xcode 12 or later required

## Using

Install the plugin for Phonegap/Cordova

    $ cordova plugin add cordova-plugin-applozic

Note: For Ionic, use

    $ ionic cordova plugin add cordova-plugin-applozic

## Android

Open your `/YOUR_PROJECT_NAME/platforms/android/app/src/main/AndroidManifest.xml`

And add the below entry tools to your `<manifest` tag

```
xmlns:tools="http://schemas.android.com/tools"
```
Example: After adding it will look like below

```
<?xml version='1.0' encoding='utf-8'?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
```

## iOS

1) Open /platforms/ios/YOUR_PROJECT_NAME.xcworkspace in Xcode.


### Steps to integrate:

Before calling any of applozic function from any file, you need to declare applozic variable at the end of that file
```js
   declare var applozic: any;
```

#### Login/Register User
```js
    var alUser = {
            'userId' : userId,   //Replace it with the userId of the logged in user it has to be string
            'password' : password,  //Put password here
            'authenticationTypeId' : 1,
            'applicationId' : 'applozic-sample-app',  //replace "applozic-sample-app" with App ID from Applozic Dashboard
            'displayName' :'display name'   //Pass display name of user
        };

   applozic.login(alUser, function() {
       applozic.registerPushNotification(function() {}, function(){});
       applozic.launchChat(function() {}, function() {});
   }, function() {});
```

NOTE: Call it after the platform is ready, for example:
```
	platform.ready().then(() => {
  		 var alUser = {
            'userId' : 'debug3',   //Replace it with the userId of the logged in user
            'password' : 'debug3',  //Put password here
            'authenticationTypeId' : 1,
            'applicationId' : 'applozic-sample-app' //replace "applozic-sample-app" with App ID from Applozic Dashboard
        };

	   applozic.login(alUser, function() {
	        		applozic.launchChat(function() {}, function() {});
	        	}, function() {});
    });
```

#### Launch Chat


##### Main Chat screen

```
applozic.launchChat(function() {console.log("success");}, function () {console.log("error");});
```

##### Launch Chat with a specific User

```
applozic.launchChatWithUserId(userId, function() {console.log("success");}, function () {console.log("error");});
```

##### Launch Chat with specific Group

```
applozic.launchChatWithGroupId(groupId, function() {console.log("success");}, function () {console.log("error");});
```


#### Contact List

```
applozic.showAllRegisteredUsers(false, function() {}, function() {});
// create a contacts array and pass it to addContacts function. Below is the sample:               
var contacts = [
                    {'userId' : 'adarsh', 'displayName' : 'Adarsh Kumar'},
                    {'userId' : 'ranjeet', 'displayName' : 'Ranjeet Priyadarshi'}
                ];
applozic.addContacts(contacts, function() {}, function() {});
```

##### Android
Set the following in platforms/android/assets/applozic-settings.json properties file.
```
"registeredUserContactListCall": false, // set to true for displaying all registered users in the contact list
"startNewButton": true,
```


### Push Notification Setup

#### Android
   Goto /platforms/android/build.gradle
   Add the following under buildscript -> dependencies
   ```
   classpath 'com.google.gms:google-services:4.0.1'
   ```

   Add the following at the bottom of the file:
   ```
   apply plugin: 'com.google.gms.google-services'
   ```

   After adding, it will look something like this:
   ```
   buildscript {
       repositories {
           mavenCentral()
           jcenter()
       }

       // Switch the Android Gradle plugin version requirement depending on the
       // installed version of Gradle. This dependency is documented at
       // http://tools.android.com/tech-docs/new-build-system/version-compatibility
       // and https://issues.apache.org/jira/browse/CB-8143
       dependencies {
         classpath 'com.android.tools.build:gradle:3.3.0'
         classpath 'com.google.gms:google-services:4.0.1'
       }
   }

   apply plugin: 'com.google.gms.google-services'
   ```

   From login success callback, call applozic.registerPushNotification(function() {}, function(){});

   For push notifications, you must have a Firebase account:
   Signup to https://console.firebase.google.com/ and create your application and generate push notification services file.

   Download google-services.json from your Firebase Console and paste it to /platforms/android/ folder

   Go to Applozic console, update the FCM Server Key from Firebase account to your Applozic account push notification section [here](https://console.applozic.com/settings/pushnotification)


#### iOS

* Creating APNs certificates and upload development and distributions certificates in applozic console you can refer this link [here](https://docs.applozic.com/docs/ios-push-notification#creating-apns-certificates)
* Open AppDelegate.m file under /platforms/ios/YOUR_PROJECT/Classes/
   Add code as mentioned in the following documentation [here](https://docs.applozic.com/docs/ios-push-notification#push-notifications)


#### Group
   ##### Create Group
   ```
     var group = {
            	'groupName': 'hey',
            	'groupMemberList': ['userid1', 'userid2', 'userid3'], // Pass list of user Ids in groupMemberList
            	'imageUrl': 'https://www.applozic.com/favicon.ico',
            	'type' : 1,    //'type' : 1, //(required) 1:private, 2:public, 5:broadcast,7:GroupofTwo
            	'metadata' : {
            		'key1' : 'value1',
            		'key2' : 'value2'
            	}
            };
     applozic.createGroup(group, function() {}, function() {});
  ```

  ##### Add Group Member
  ```
    var groupDetails = {
        'groupId': GROUP_ID,
        'clientGroupId': CLIENT_GROUP_ID, //use either groupId or clientGroupId
        'userId': USER_ID_TO_ADD
    }
    applozic.addGroupMember(groupDetails, function() {}, function() {});
  ```


  ##### Remove Group Member
  ```
    var groupDetails = {
        'groupId': GROUP_ID,
        'clientGroupId': CLIENT_GROUP_ID, //use either groupId or clientGroupId
        'userId': USER_ID_TO_ADD
    }
    applozic.removeGroupMember(groupDetails, function() {}, function() {});
  ```

#### Topic Based Chat

 ```
       var topicDetail = {
                        'title': 'Hyundai Electric i20', // Product title
                        'subtitle': 'electric car',      // Product subTitle or Product Id
                        'link': 'https://www.applozic.com/assets/resources/images/applozic_logo.gif',  // Product image link
                        'key1': 'Mileage: ',  // Small text anything like Qty (Optional)
                        'value1': '18 kmpl',  // Value of key1 ex-10 (number of quantity) Optional
                        'key2': 'Price: ',    // Small text anything like MRP (product price) (Optional)
                        'value2': '$50k'   // Value of key2 ex-$100  (Optional)
                    };
                    var conversation = {
                        'topicId': 'topic-11', //Unique topic id
                        'userId': 'demouser', //SET UserId for which you want to launch chat or conversation,
                       // 'groupId': groupKey,  // Set groupId for which you want to launch chat, use either userId or groupId
                        'topicDetail': JSON.stringify(topicDetail)
                    };

                    applozic.startTopicBasedChat(conversation, function() {}, function() {});
 ```


#### Logout

```
applozic.logout(function() {console.log("success");}, function () {console.log("error");});
```

### Unread count

#### Total unreadcount

```
   applozic.getUnreadCount(function(response){
     var count = response;
    },
    function(error){alert(error)
   });

```

#### Unread count for user

```
   var userId = 'USER_ID'; //pass UserId with which unread count
   applozic.getUnreadCountForUser(userId,function(response){
     var count = response;
    },
    function(error){alert(error)
   });

```


#### Unread count for group

```
   var groupId = 'GROUP_ID'; // pass groupId in which unreadcount required

  applozic.getUnreadCountForGroup(groupId,function(response){
       var count = response;
    },
     function(error){
    });

```

Install iOS or Android platform

    cordova platform add ios
    cordova platform add android

Run the code

    cordova run



  # Resolving Errors

  ### Gradle wrapper error

   Open /platforms/android/ folder in Android Studio.
   If you see gradle wrapper error then open gradle/wrapper/gradle-wrapper.properties
  Change distributionUrl to point to 4.10.3-all

  distributionUrl=https\://services.gradle.org/distributions/gradle-4.10.3-all.zip


   ### Android support libraries/google versions conflict


If using multiple plugins that use support libraries or google dependencies, you may get support libraries or firebase version conflict issues in android. Use the below gradle script in your app/platform/android/build.gradle file's dependencies :

     dependencies {
  		configurations.all {
   	 	 resolutionStrategy.eachDependency { DependencyResolveDetails details ->
        	 def requested = details.requested
        	 if (requested.group == 'com.google.firebase' || requested.group == 'com.google.android.gms') {
         	   details.useVersion '15.0.0'  //use a common firebase/google version here
        	  }

        	  if (requested.group == 'com.android.support' && requested.name != 'multidex') {
         		   details.useVersion '27.1.1'  //use a common support libraries version here

      	           }

                 }
		 }  
          }

### iOS Swift version issue

Older versions of the plugin may give the build error "Swift version not specified". Open the YourProject.xcworkspace from yourApp/platforms/ios directory in your Xcode and build the project. Then click on the Kommunicate module and specify the SWIFT_VERSION.







## More Info

For more information on setting up Cordova see [the documentation](http://cordova.apache.org/docs/en/latest/guide/cli/index.html)

For more info on plugins see the [Plugin Development Guide](http://cordova.apache.org/docs/en/latest/guide/hybrid/plugins/index.html)
