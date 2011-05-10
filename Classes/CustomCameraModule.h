/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiModule.h"
#import "KrollCallback.h"
#import "TiViewProxy.h"
#import "TiUIImageViewProxy.h"
#import "TiFilesystemFileProxy.h"
#import "TiBlob.h"

@interface CustomCameraModule : TiModule <
	UINavigationControllerDelegate,
	UIImagePickerControllerDelegate
>
{
	UIImagePickerController *picker;
	UIImage* image;
	TiViewProxy* overlayView;
	NSString *overlayFilename;
	TiBlob* previewBlob;
	float compress;
}

@property(nonatomic,retain) UIImagePickerController *picker;
@property(nonatomic,retain) UIImage* image;
@property(nonatomic,retain) TiViewProxy* overlayView;
@property(nonatomic,retain) NSString *overlayFilename;
@property(nonatomic,retain) TiBlob* previewBlob;
@property(nonatomic,assign) float compress;


@property(nonatomic,readonly) NSNumber* UNKNOWN_ERROR;
@property(nonatomic,readonly) NSNumber* DEVICE_BUSY;
@property(nonatomic,readonly) NSNumber* NO_CAMERA;
//@property(nonatomic,readonly) NSArray* availableCameraMediaTypes;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@property(nonatomic,readonly) NSNumber* CAMERA_FRONT;
@property(nonatomic,readonly) NSNumber* CAMERA_REAR;
//@property(nonatomic,readonly) NSArray* availableCameras;

@property(nonatomic,readonly) NSNumber* CAMERA_FLASH_OFF;
@property(nonatomic,readonly) NSNumber* CAMERA_FLASH_AUTO;
@property(nonatomic,readonly) NSNumber* CAMERA_FLASH_ON;
#endif

@end
