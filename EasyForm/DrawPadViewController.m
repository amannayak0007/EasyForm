//
//  DrawPadViewController.m
//  GraffitoDrawPadApp
//
//  Created by Rahiem Klugh on 8/17/15.
//  Copyright (c) 2015 TouchCore Logic, LLC. All rights reserved.
//

#import "DrawPadViewController.h"

@implementation DrawPadViewController
@synthesize toolbar,navbar, drawerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Edit Photo";
    //Initial view setup
    [self setupDrawPadView];
    [self determineLineColorAndWithSettings];
    [self setupTopNavBar];
    [self setupBottomToolBar];
    [self setupNotifications];
}

//Init the drawpad view
-(void) setupDrawPadView
{
    drawerView = [[DrawPadUIView alloc] init];
    if (self.imageView.image)
    {
        self.imageView.image = nil;
    }
    
    //Need to resize image view based on the size of the image imported
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = _originalImage;
    
    double width = _originalImage.size.width;
    double height = _originalImage.size.height;
    double apectRatio = width/height;
    double newHeight = [[UIScreen mainScreen] bounds].size.width/ apectRatio;
    double newWidth = [[UIScreen mainScreen] bounds].size.width;
    
    //Adjust the new image frame size differently for a screenshot
    if (apectRatio < 0.6)
    {
        newWidth = newWidth-50;
        newHeight = newHeight-50;
    }
    
    //For EASYFORM
    double yTransform =30;
    
    CGRect newWindowFrame =  CGRectMake(0,yTransform,newWidth, newHeight);
    
    self.imageView.frame = newWindowFrame;
    self.imageView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2-30);//self.view.center;
    
    //Adjust the new draw pad frame size differently for a screenshot
    if (apectRatio < 0.6)
    {
        newHeight = newHeight-38;
    }
    
    //Change the frame of the draw pad view to be identical to the image loaded
    drawerView.frame= CGRectMake(0,yTransform,newWidth, newHeight);
    drawerView.center = self.imageView.center;
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:drawerView];

}

//Checks the user defaults to determine the settings for a users brush color and width
-(void) determineLineColorAndWithSettings
{
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userColor"];
    if (colorData == nil)
    {
        drawerView.lineColor = [UIColor redColor];
    }
    else
    {
        UIColor *selectedColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        drawerView.lineColor = selectedColor;
    }
    
    CGFloat brushSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"userBrushSize"];
    if (brushSize <= 0.1)
    {
        drawerView.lineWidth = 6.0f;
    }
    else
    {
        drawerView.lineWidth = brushSize;
    }
}

//Configures the navigation bar for the view
-(void) setupTopNavBar
{
    CGRect frameimg = CGRectMake(0, 0, 56 , 30);
    UIButton* _goButton = [[UIButton alloc] initWithFrame:frameimg];
    [_goButton setTitle:@"Done" forState:UIControlStateNormal];
    [_goButton addTarget:self action:@selector(doneButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];
    [_goButton setShowsTouchWhenHighlighted:YES];
    _goButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _goButton.layer.borderWidth = 1.0;
    _goButton.layer.cornerRadius = 8;
    _goButton.layer.masksToBounds = YES;

    UIBarButtonItem *gbutton =[[UIBarButtonItem alloc] initWithCustomView:_goButton];
    self.navigationItem.rightBarButtonItem=gbutton;
}

//Configures the tool bar for the view
-(void) setupBottomToolBar
{
    UIBarButtonItem *barButtonUndo = [self createImageButtonItemWithNoTitle:@"UndoIcon" pressedImage:@"UndoHighlighted" target:self action:@selector(undoDrawing)];
    UIBarButtonItem *barButtonRedo = [self createImageButtonItemWithNoTitle:@"RedoIcon" pressedImage:@"RedoHighlighted" target:self action:@selector(redoDrawing)];
    UIBarButtonItem *barButtonFlexibleGap = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolbar.items = [NSArray arrayWithObjects:barButtonFlexibleGap,barButtonFlexibleGap,barButtonFlexibleGap,barButtonUndo,barButtonFlexibleGap,barButtonRedo, barButtonFlexibleGap, barButtonFlexibleGap, barButtonFlexibleGap, nil];
}

//Register all notifications
-(void) setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveToPhotoAlbum)
                                                 name:@"Save to Photo Album"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendToMessage)
                                                 name:@"Message"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrushColor)
                                                 name:@"updateBrushColor"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrushSize)
                                                 name:@"updateBrushSize"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupTopNavBar)
                                                 name:@"updateNavBar"
                                               object:nil];
}

//Creates a standard tool bar button
-(UIBarButtonItem *)createImageButtonItemWithNoTitle:(NSString *)imageNormal pressedImage: (NSString *)imageHighlighted target:(id)tgt action:(SEL)a
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    CGRect buttonFrame = [button frame];
    buttonFrame.size.width = 26;
    buttonFrame.size.height = 26;
    [button setFrame:buttonFrame];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 3, 26, 26)];
    imageView.image = [UIImage imageNamed:imageNormal];
    [button setBackgroundImage:imageView.image forState:UIControlStateNormal];
    
    UIImageView *imageViewTouched = [[UIImageView alloc]initWithFrame:CGRectMake(0, 3, 26, 26)];
    imageViewTouched.image = [UIImage imageNamed:imageHighlighted];
    [button setBackgroundImage:imageViewTouched.image forState:UIControlStateHighlighted];
    
    [button addTarget:tgt action:a forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return buttonItem;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Action methods
- (IBAction)cameraButtonPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Draw on an image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Import Photo", @"Take Photo", nil];
    [actionSheet showInView:self.view];
}


//Fetches the images from the Canvas then saves it to the camera roll
-(void) saveToPhotoAlbum
{
    UIImage *image = [self getImageFromCanvas];
    
}

//Return the complete canvas view (Drawing + Image)
-(UIImage*) getImageFromCanvas
{
    UIImage *drawingImage;
    if (self.imageView.image ==nil)
    {
        drawingImage =  [drawerView imageRepresentation:nil];
    }
    else
    {
        drawingImage =  [drawerView imageRepresentation:self.imageView];
    }
    return drawingImage;
}

//Enables the eraser
-(void) eraseButtonPressed
{
    drawerView.drawTool = ACEDrawingToolTypeEraser;
    //[ProgressHUD showSuccess:nil];
}

-(void) undoDrawing
{
    [drawerView canUndo];
    [drawerView undoLatestStep];
}

-(void) redoDrawing
{
    [drawerView canRedo];
    [drawerView redoLatestStep];
}

-(void) colorButtonPressed
{
    drawerView.drawTool = ACEDrawingToolTypePen;
    [self performSegueWithIdentifier:@"showBrushMenu" sender:self];
}

//Enable the brush tool or show the brush menu if the brush tool is already enabled
-(void) brushButtonPressed
{
    if (drawerView.drawTool == ACEDrawingToolTypeEraser)
    {
        drawerView.drawTool = ACEDrawingToolTypePen;
       // [ProgressHUD showError:nil];
    }
    else
    {
       [self performSegueWithIdentifier:@"showBrushMenu" sender:self];
    }
}

-(void) trashButtonPressed
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Erase Canvas" message:@"The entire canvas will be erased and cannot be undone. Are you sure you want to erase?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Erase", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        [self clearDrawPad];
    }
}


-(void) clearDrawPad
{
    if (self.imageView.image)
    {
        self.imageView.image = nil;
    }
    [drawerView clear];
    [self setupDrawPadView];
    [self determineLineColorAndWithSettings];
}


-(void)doneButtonPressed{
    UIImage *image = [self getImageFromCanvas];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"imageAdded" object:self
                                                      userInfo:@{ @"editedImage" : image}];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - MessageComposerDelegate methods

//Opens the iOS message composer
-(void) sendToMessage
{
    UIImage *image = [self getImageFromCanvas];
    
    MFMessageComposeViewController* messageComposer = [MFMessageComposeViewController new];
    messageComposer.messageComposeDelegate = self;
    [messageComposer setBody:@""];
    NSData *imageData = UIImagePNGRepresentation(image);
    [messageComposer addAttachmentData:imageData typeIdentifier:(NSString *)kUTTypePNG   filename:@"image.png"];
    [self presentViewController:messageComposer animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    
    if (buttonIndex != 2)
    {
        if (buttonIndex == 0)
        {
            imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imgPicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        }
        else
        {
            imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        
        imgPicker.allowsEditing = NO;
        imgPicker.delegate = self;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }
}

#pragma mark - BrushMenuViewControllerDelegate methods

//Updates the brush color to match user selection
-(void) updateBrushColor
{
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"userColor"];
    UIColor *selectedColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    drawerView.lineColor = selectedColor;
}

-(void) updateBrushSize
{
    drawerView.lineWidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"userBrushSize"];
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //Send the current brush size and color data to the brush menu view controller
    BrushMenuViewController* vc = [segue destinationViewController];
    vc.currentSelectedColor = drawerView.lineColor;
    vc.currentSelectedBrushSize = drawerView.lineWidth;
}

@end