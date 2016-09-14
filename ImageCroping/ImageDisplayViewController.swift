//
//  ImageDisplayViewController.swift
//
//  Objective: Crop and Save images from your Photo
//  library or Camera.
//
//  Acknowledgement : Duncan Champney
// 
//  Created by Sanjay noronha on 8/19/16.
//  Copyright © 2016 funza Academy. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: Global functions

/*
 * Used in delaying playing the shutter sound, for example
*/
func delay(delay: Double, block:()->())
{
    let nSecDispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)));
    let queue = dispatch_get_main_queue()
    
    dispatch_after(nSecDispatchTime, queue, block)
}

/* 
 * Play a Sound when the user Crops an Image
*/
func loadShutterSoundPlayer() -> AVAudioPlayer?
{
    let theMainBundle = NSBundle.mainBundle()
    let soundfilePath: String? = theMainBundle.pathForResource(MasterData.filename,
                                                               ofType: MasterData.fileType,
                                                               inDirectory: nil)
    if soundfilePath == nil
    {
        return nil
    }
    
    let fileURL = NSURL.fileURLWithPath(soundfilePath!)
    var error: NSError?
    let result: AVAudioPlayer?
    do {
        result = try AVAudioPlayer(contentsOfURL: fileURL)
    } catch let error1 as NSError {
        error = error1
        result = nil
    }
    if let requiredErr = error
    {
        print("AVAudioPlayer.init failed with error \(requiredErr.debugDescription)")
    }
    
    result?.prepareToPlay()
    return result
}


class ImageDisplayViewController:UIViewController,UIImagePickerControllerDelegate,
UINavigationControllerDelegate{
    
    
    @IBOutlet  var cropView: CroppableImageView! //The View where the magic happens

    @IBOutlet weak var whiteView: UIView! // Curtain view
    
    var shutterSoundPlayer = loadShutterSoundPlayer()
    


    @IBAction func didSelectImage(sender: AnyObject) {
        
        /* hide instructions from the user */
        self.whiteView.hidden = true
        
        
        /*See if the current device has a camera.
          But the simulator doesn't offer a camera, 
          so this prevents the
          "Take a new picture" button from crashing the simulator.
         */
        let deviceHasCamera: Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)

        
        //Create an alert controller that asks the user what type of image to choose.
        let anActionSheet = UIAlertController(title: MasterData.alertControllerTitle,
                                              message: nil,
                                              preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        
        //If the current device has a camera, add a "Take a New Picture" button
        var takePicAction: UIAlertAction? = nil
        if deviceHasCamera
        {
            takePicAction = UIAlertAction(
                title: MasterData.takeNewPicture,
                style: UIAlertActionStyle.Default,
                handler:
                {
                    (alert: UIAlertAction)  in
                    self.pickImageFromSource(
                        ImageSource.Camera,
                        fromButton: sender as! UIBarButtonItem)
                }
            )
        }
        
        //Allow the user to select an Image from their photo library
        let selectPicAction = UIAlertAction(
            title:MasterData.useExistingPic,
            style: UIAlertActionStyle.Default,
            handler:
            {
                (alert: UIAlertAction)  in
                self.pickImageFromSource(
                    ImageSource.PhotoLibrary,
                    fromButton: sender as! UIBarButtonItem)
            }
        )
        
        let cancelAction = UIAlertAction(
            title:MasterData.cancel,
            style: UIAlertActionStyle.Cancel,
            handler:
            {
                (alert: UIAlertAction)  in
                
                guard let _ = self.cropView.imageToCrop else {
                    self.whiteView.hidden = false
                    return
                }
            }
        )
        
        if let requiredtakePicAction = takePicAction
        {
            anActionSheet.addAction(requiredtakePicAction)
        }
        anActionSheet.addAction(selectPicAction)
        anActionSheet.addAction(cancelAction)
        
        let popover = anActionSheet.popoverPresentationController
        popover?.sourceView = sender as? UIView
        popover?.sourceRect = sender.bounds;
        
        self.presentViewController(anActionSheet, animated: true)
        {
            //println("In action sheet completion block")
        }
    }
    
    
    @IBAction func didCropImage(sender: AnyObject) {
        
        if let croppedImage = cropView.croppedImage()
        {
            //self.whiteView.hidden = false
            delay(0)
            {
                self.shutterSoundPlayer?.play()
                
                /* Save the Cropped Image to the Photo Album */
                UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil);

                
                delay(0.2)
                {
                    self.whiteView.hidden = false
                    self.shutterSoundPlayer?.prepareToPlay()
                    /* Now uncrop the image */
                    self.cropView.cropRect = nil
                }
            }
        
        }
    }
 
    
    
}

extension ImageDisplayViewController {
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
            cropView.imageToCrop = image
            cropView.contentMode = UIViewContentMode.ScaleAspectFit
        }
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController)
    {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension ImageDisplayViewController {
    
    enum ImageSource: Int
    {
        case Camera = 1
        case PhotoLibrary
    }
    
    func pickImageFromSource(
        theImageSource: ImageSource,
        fromButton: UIBarButtonItem)
    {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        switch theImageSource
        {
        case .Camera:
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.cameraDevice = UIImagePickerControllerCameraDevice.Front;
        case .PhotoLibrary:
            imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        }
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad
        {
            if theImageSource == ImageSource.Camera
            {
                self.presentViewController(
                    imagePicker,
                    animated: true)
                {
                    //println("In image picker completion block")
                }
            }
            else
            {
                self.presentViewController(
                    imagePicker,
                    animated: true)
                {
                    //println("In image picker completion block")
                }
            }
        }
        else
        {
            self.presentViewController(
                imagePicker,
                animated: true)
            {
                //print("In image picker completion block")
            }
            
        }
    }

    
}
