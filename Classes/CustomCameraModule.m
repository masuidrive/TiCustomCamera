/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "CustomCameraModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "TiApp.h"
#import "TiBlob.h"
#import "TiFile.h"
#import "TiUIViewProxy.h"
#import "Ti2DMatrix.h"

#define kCameraScale 1.12412178 //= 480 / 427
#define kCameraOffset 26.5 //= (480 - 427) / 2

enum  
{
	MediaModuleErrorUnknown,
	MediaModuleErrorBusy,
	MediaModuleErrorNoCamera
};

@implementation CustomCameraModule
@synthesize picker, image, overlayView, overlayFilename, previewBlob;
@synthesize compress;


#pragma mark Lifecycle

-(void)startup
{
	[super startup];
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)destroyPicker
{
	self.previewBlob = nil;
	self.image = nil;
	self.overlayFilename = nil;
	self.overlayView = nil;
	self.picker = nil;
}

-(void)dealloc
{
	[self destroyPicker];
	[super dealloc];
}


#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	[super didReceiveMemoryWarning:notification];
}


#pragma Internal

-(void)sendPickerError:(int)code
{
	if ([self _hasListeners:@"error"])
	{
		NSDictionary *event = [NSDictionary dictionaryWithObject:NUMINT(code) forKey:@"code"];
		[self fireEvent:@"error" withObject:event];
	}
}

-(void)sendPickerCancel
{
	if ([self _hasListeners:@"cancel"])
	{
		NSDictionary *event = [NSDictionary dictionary];
		[self fireEvent:@"cancel" withObject:event];
	}
}

-(void)sendPickerSuccess
{
	if ([self _hasListeners:@"success"])
	{
		NSDictionary *event = [NSDictionary dictionary];
		[self fireEvent:@"success" withObject:event];
	}
}

-(BOOL)createPicker
{
	if (picker!=nil)
	{
		[self sendPickerError:MediaModuleErrorBusy];
		return NO;
	}
	self.picker = [[[UIImagePickerController alloc] init] autorelease];
	[picker setDelegate:self];
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		[self sendPickerError:MediaModuleErrorNoCamera];
		return NO;
	}
	[picker setSourceType:UIImagePickerControllerSourceTypeCamera];
	
	if (overlayView!=nil)
	{
		[TiUtils setView:overlayView.view positionRect:picker.view.frame];
		picker.cameraOverlayView = overlayView.view;
		picker.showsCameraControls = NO;
		picker.wantsFullScreenLayout = YES;
	}
	
	picker.cameraViewTransform = CGAffineTransformMake(kCameraScale, 0.0f,
													   0.0f,         kCameraScale,
													   0.0f,         kCameraOffset);
	return YES;
}

- (UIImageView*)setLandscapeImage:(UIImageView*)view size:(CGSize)size
{
	view.contentMode = UIViewContentModeScaleAspectFill;
	[TiUtils setView:view positionRect:picker.view.frame];
	
	int orientation = image.imageOrientation;
	float rotate[4] = {90.0, 270.0, 180.0, 0.0};
	CGAffineTransform transform = CGAffineTransformMakeRotation(rotate[orientation]*M_PI/180.0);
	if(orientation==0 || orientation==1) { // landscape
		view.frame = CGRectMake(0.0f, 0.0f, size.height, size.width);
		float offset = fabs(size.height - size.width)/2;
		if(orientation==0) {
			view.transform = CGAffineTransformTranslate(transform, offset, offset);
		}
		else {
			view.transform = CGAffineTransformTranslate(transform, -1.0*offset, -1.0*offset);
		}			
	}
	else {
		view.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
	}
	return view;
}

- (UIImageView*)createLandscapeImage:(CGSize)size
{
	UIImageView* view = [[[UIImageView alloc] initWithImage:image] autorelease];
	return [self setLandscapeImage:view size:size];
}


#pragma Delegates

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker_
{
	[self sendPickerCancel];
}

- (void)imagePickerController:(UIImagePickerController *)picker_ didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self sendPickerSuccess];
}


#pragma Public APIs

MAKE_SYSTEM_PROP(UNKNOWN_ERROR,MediaModuleErrorUnknown);
MAKE_SYSTEM_PROP(DEVICE_BUSY,MediaModuleErrorBusy);
MAKE_SYSTEM_PROP(NO_CAMERA,MediaModuleErrorNoCamera);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
MAKE_SYSTEM_PROP(CAMERA_FRONT,UIImagePickerControllerCameraDeviceRear);
MAKE_SYSTEM_PROP(CAMERA_REAR,UIImagePickerControllerCameraDeviceFront);

MAKE_SYSTEM_PROP(CAMERA_FLASH_OFF,UIImagePickerControllerCameraFlashModeOff);
MAKE_SYSTEM_PROP(CAMERA_FLASH_AUTO,UIImagePickerControllerCameraFlashModeAuto);
MAKE_SYSTEM_PROP(CAMERA_FLASH_ON,UIImagePickerControllerCameraFlashModeOn);
#endif


-(void)open:(id)args
{
	ENSURE_UI_THREAD(open, args);
	ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
	
	self.compress = [TiUtils floatValue:[args objectForKey:@"compress"]];
	
	id overlay = [args objectForKey:@"overlay"];
	if(overlay) {
		ENSURE_TYPE(overlay, TiViewProxy);
		self.overlayView = overlay;
	}
	
	if([self createPicker]) {
		TiApp * tiApp = [TiApp app];
		[[tiApp controller] manuallyRotateToOrientation:UIInterfaceOrientationPortrait];
		[tiApp showModalController:picker animated:YES];
	}
}

-(void)take:(id)args
{
	ENSURE_UI_THREAD(take, args);
	
	if (picker==nil)
	{
		[self throwException:@"invalid state" subreason:nil location:CODELOCATION];
	}
	[picker takePicture];
}

-(void)close:(id)args
{
	ENSURE_UI_THREAD(close, args);
	
	if (picker!=nil)
	{
		[[TiApp app] hideModalController:picker animated:NO];
		[self destroyPicker];
	}
}

-(void)save:(id)args
{
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(save:) withObject:args waitUntilDone:YES modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		return;
	}
	ENSURE_ARG_COUNT(args, 2);
	NSString* saveFile = [TiUtils stringValue:[args objectAtIndex:0]];
	NSString* overlayFile = [TiUtils stringValue:[args objectAtIndex:1]];
	
	UIImage* oimage = [UIImage imageWithContentsOfFile:overlayFile];
	CGRect rect = CGRectMake(0.0f, 0.0f, oimage.size.width, oimage.size.height);
	UIView* view = [[[UIView alloc] initWithFrame:rect] autorelease];
	[view addSubview:[self createLandscapeImage:rect.size]];
	
	UIImageView* iview = [[[UIImageView alloc] initWithImage:oimage] autorelease];
	iview.frame = rect;
	[view addSubview:iview];
	
	UIGraphicsBeginImageContext(view.frame.size);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	UIImage* canvas = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	NSData* data = UIImageJPEGRepresentation(canvas, compress);
	[data writeToFile:saveFile atomically:YES];
}

-(void)createPreview:(id)args
{
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(createPreview:) withObject:args waitUntilDone:YES modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		return;
	} 

	CGRect rect = CGRectMake(0.0f, 0.0f, picker.view.frame.size.width, picker.view.frame.size.height);
	UIView* view = [[[UIView alloc] initWithFrame:rect] autorelease];
	[view addSubview:[self createLandscapeImage:rect.size]];
	
	UIImageView* iview = [[[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:overlayFilename]] autorelease];
	iview.frame = rect;
	[view addSubview:iview];

	UIGraphicsBeginImageContext(view.frame.size);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];

	UIImage* canvas = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.previewBlob = [[[TiBlob alloc] initWithImage:canvas] autorelease];
}

@end
