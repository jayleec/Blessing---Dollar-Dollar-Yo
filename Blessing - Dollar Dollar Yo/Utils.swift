//
//  Utils.swift
//
//  Created by Jay on 04/08/2017.
//  Copyright © 2017 ninjajaekyung. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AVFoundation

var player : AVAudioPlayer?

extension URL {
    static public func randomUrl() -> URL {
        let path = NSTemporaryDirectory() + "/" + String.random(length: 5) + ".mov"
        return URL(fileURLWithPath: path)
    }
    
    public func saveToAlbum() {
        UISaveVideoAtPathToSavedPhotosAlbum(self.path, nil, nil, nil)
    }
}

extension String {
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
}


class Utils {
    
    static public var successSoundPlaying: (() -> Void)? = {
        AudioServicesPlaySystemSound(1075)
    }
    
    static func playSound(soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            
            player.play()
            
            
        }catch let error {
            print(error)
        }
    }
    
    static func showAlert(viewCtr:UIViewController, title:String, message:String, dismiss:Bool) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if dismiss {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in viewCtr.dismiss(animated: true, completion: nil)}))
        } else {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        viewCtr.present(controller, animated: true, completion: nil)
    }
    
    static func checkPhotoLibraryAuthorization(view: UIViewController){
        let status = PHPhotoLibrary.authorizationStatus()
        print("authorization check \(status)")
        
        if (status == PHAuthorizationStatus.notDetermined){
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized){
                    showAlert(viewCtr:view, title: "Photo Library", message:"Photo Library Access Allowed" , dismiss: false)
                }else{
                    showAlert(viewCtr:view, title: "Photo Library", message:"Photo Library Access Not Allowed" , dismiss: false)
                }
            })
        }
    }
    
    static func checkAuthorizationAndPresentActivityController(toShare data: Any, using presenter: UIViewController) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.openInIBooks, UIActivityType.print]
            presenter.present(activityViewController, animated: true, completion: nil)
        case .restricted, .denied:
            let libraryRestrictedAlert = UIAlertController(title: "Photos access denied",
                                                           message: "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots.",
                                                           preferredStyle: UIAlertControllerStyle.alert)
            libraryRestrictedAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            presenter.present(libraryRestrictedAlert, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    let activityViewController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                    activityViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.openInIBooks, UIActivityType.print]
                    presenter.present(activityViewController, animated: true, completion: nil)
                }
            })
        }
    }
}

