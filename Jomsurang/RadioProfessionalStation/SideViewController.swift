//
//  SideViewController.swift
//  RadioProfessionalStation
//
//  Created by JakkritS on 2/9/2559 BE.
//  Copyright © 2559 AppIllustrator. All rights reserved.
//

import UIKit
import MessageUI
import Material

class SideViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    let infoButton = FabButton()
    let mailButton = FabButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let localFilePath = NSBundle.mainBundle().URLForResource("songHistory", withExtension: "html")
        let myRequest = NSURLRequest(URL: localFilePath!)
        webView.opaque = false
        webView.backgroundColor = UIColor.clearColor()
        webView.loadRequest(myRequest)
        
        let blurEffect = UIBlurEffect(style: .Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        //view.addSubview(blurEffectView)
        
        let infoImg = UIImage(named: "radio57")
        infoButton.setImage(infoImg, forState: .Normal)
        infoButton.setImage(infoImg, forState: .Highlighted)
        infoButton.addTarget(self, action: "websiteButtonDidTouch", forControlEvents: .TouchUpInside)
        infoButton.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
        view.addSubview(infoButton)
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        MaterialLayout.alignFromBottomLeft(view, child: infoButton, bottom: 16, left: 16)
        MaterialLayout.size(view, child: infoButton, width: 32, height: 32)
        
        let mailImg = UIImage(named: "mail")
        mailButton.setImage(mailImg, forState: .Normal)
        mailButton.setImage(mailImg, forState: .Highlighted)
        mailButton.addTarget(self, action: "emailButtonDidTouch", forControlEvents: .TouchUpInside)
        mailButton.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
        view.addSubview(mailButton)
        mailButton.translatesAutoresizingMaskIntoConstraints = false
        MaterialLayout.alignFromBottomRight(view, child: mailButton, bottom: 16, right: 16)
        MaterialLayout.size(view, child: mailButton, width: 32, height: 32)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func emailButtonDidTouch() {
        
        let receipients = ["appillustrator.com@gmail.com"]
        let subject = "iOS Radio App:"
        let messageBody = ""
        
        let configuredMailComposeViewController = configureMailComposeViewController(receipients, subject: subject, messageBody: messageBody)
        
        if canSendMail() {
            self.presentViewController(configuredMailComposeViewController, animated: true, completion: nil)
        } else {
            showSendMailErrorAlert()
        }
    }
    
    func websiteButtonDidTouch() {
        
        if let url = NSURL(string: "http://appillustrator.com/radioApp") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    
}

extension SideViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func configureMailComposeViewController(recepients: [String], subject: String, messageBody: String) -> MFMailComposeViewController {
        
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(recepients)
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody(messageBody, isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Mail Error", message: "Could not send email, plase try again!", preferredStyle: UIAlertControllerStyle.Alert)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
