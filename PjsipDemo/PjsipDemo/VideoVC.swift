//
//  VideoVC.swift
//  PjsipDemo
//
//  Created by Apple on 19/05/23.
//

import UIKit

class VideoVC: UIViewController {

    @IBOutlet var videoView : UIView!
    var customVideo : UIView =  UIView()
    override func viewDidLoad() {
        super.viewDidLoad()
        customVideo.frame = videoView.frame
        videoView.addSubview(customVideo)
    }
    
}
