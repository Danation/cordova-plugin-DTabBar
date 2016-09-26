import Foundation
import UIKit
import UIKit.UITabBar
import WebKit

@objc(DTabBar) public class DTabBar : CDVPlugin, UITabBarDelegate {
    
    // Note: These initializers actually don't do anything.  They need to be initialized again in create() *shrug*
    private var tabBarHeight:CGFloat = 0
    private var statusBarHeight:CGFloat = 0
    
    private var portraitViewHeight:CGFloat?
    private var portraitViewWidth:CGFloat?
    private var landscapeViewHeight:CGFloat?
    private var landscapeViewWidth:CGFloat?
    
    private var tabBarItems = Dictionary<String, UITabBarItem>()
    private var tabItemURLs = Dictionary<String, String>()
    
    private var tabBar:UITabBar = UITabBar()
    
    private var homeUrl = ""
    
    override public func pluginInitialize() {
        homeUrl = commandDelegate.settings["homeurl"] as! String;
    }
    
    @objc(create:)
    func create(command : CDVInvokedUrlCommand) {
        statusBarHeight = 20.0
        tabBarHeight = 49.0

        tabBarItems = Dictionary<String, UITabBarItem>()
        tabItemURLs = Dictionary<String, String>()
        tabBar = UITabBar()
        // Add an event handler for orientation change so that the tab bar does not get "stuck"
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(DTabBar.orientationChanged),
                                                         name: NSNotification.Name.UIDeviceOrientationDidChange,
                                                         object: nil)
        
        // Set up tab bar
        tabBar.sizeToFit()
        tabBar.isHidden = true
        tabBar.delegate = self
        tabBar.isMultipleTouchEnabled = false
        tabBar.autoresizesSubviews = true
        tabBar.isUserInteractionEnabled = true
        tabBar.isOpaque = true

        // Add tab bar items
        
        if let options = command.arguments[0] as? [String: AnyObject] {
            if let iconTint = options["iconTintColor"] as? NSString {
                tabBar.tintColor = colorStringToColor(input: iconTint)
            }
            
            var tag = 0;
            if let items = options["items"] as? [[String:String]] {
                var tabBarItemArray:[UITabBarItem] = Array<UITabBarItem>()
                for item in items {
                    // Get image
                    if let imagePath = Bundle.main.path(forResource: item["imageFilename"], ofType: "png") {
                        let tabImage = UIImage(contentsOfFile: imagePath)
                        
                        // Create the tab item
                        let tabBarItem = UITabBarItem(title: item["label"], image: tabImage, tag: tag)
                        tag += 1
                        tabBarItemArray.append(tabBarItem)
                        
                        // Add to lookup tables
                        tabBarItems[item["relativeUrl"]!] = tabBarItem
                        tabItemURLs[item["label"]!] = item["relativeUrl"]!
                    }
                }
                tabBar.items = tabBarItemArray
            }
        }
        
        webView!.superview!.autoresizesSubviews = true
        
        // Add to web view and resize
        webView!.superview!.addSubview(tabBar)
        
        correctViewFrames()
    }
    
    @objc(setVisible:)
    func setVisible(command : CDVInvokedUrlCommand) {
        let shouldShow = command.arguments[0] as! Bool
        tabBar.isHidden = !shouldShow
        correctViewFrames()
    }

    @objc(selectItem:)
    func selectItem(command : CDVInvokedUrlCommand) {
        let itemName = command.arguments[0] as! String
        if let tabBarItem = tabBarItems[itemName] {
            tabBar.selectedItem = tabBarItem
        }
        else {
            tabBar.selectedItem = nil
        }
    }
    
    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let relativeUrl = tabItemURLs[item.title!] {
            let newUrl = homeUrl + relativeUrl
            let request = NSURLRequest(url: NSURL(string: newUrl)! as URL)
            
            if (self.webView is UIWebView) {
                (self.webView as! UIWebView).loadRequest(request as URLRequest)
            }
            else if (self.webView is WKWebView) {
                (self.webView as! WKWebView).load(request as URLRequest)
            }
        }
    }
    
    func colorStringToColor(input : NSString) -> UIColor {
        let stringComponents = input.components(separatedBy: ",")
        
        // String to CGFloat conversion
        let cgfloatComponents = stringComponents.map {
            CGFloat(($0 as NSString).doubleValue)/255
        }
        let result = UIColor(red: cgfloatComponents[0],
            green: cgfloatComponents[1],
            blue: cgfloatComponents[2],
            alpha: cgfloatComponents[3])
        return result
    }
    
    // When device orientation changes, fix the WebView frame
    func orientationChanged(notification : NSNotification) {
        correctViewFrames()
    }
    
    func correctViewFrames() {
        correctTabBarFrame()
        correctWebViewFrame()
    }
    
    func correctWebViewFrame() {
        if tabBar.isHidden {
            return;
        }
        
        var navBarHeight:CGFloat = 44
        
        // Check if NavBar is shown
        var navBarShown:Bool = false
        let parent = tabBar.superview!
        for view:UIView in parent.subviews as Array<UIView> {
            if view is UINavigationBar {
                navBarShown = !view.isHidden
                navBarHeight = view.frame.height
                break
            }
        }
        
        let parentSize = webView!.superview?.bounds
        let left:CGFloat = parentSize!.origin.x
        let right:CGFloat = left + parentSize!.size.width
        
        var top:CGFloat = parentSize!.origin.y
        let bottom:CGFloat = top + parentSize!.size.height - tabBarHeight
        
        if navBarShown {
            top += navBarHeight
        }
        
        webView!.frame = CGRect(x: left,
            y: top + statusBarHeight,
            width: right - left,
            height: bottom - (top + statusBarHeight))
        
    }
    
    func correctTabBarFrame() {
        
        if tabBar.isHidden {
            return
        }
        
        let parentSize = webView!.superview?.bounds
        let left:CGFloat = parentSize!.origin.x
        
        var right:CGFloat = left + parentSize!.size.width
        var bottom:CGFloat = parentSize!.origin.y + parentSize!.size.height - tabBarHeight
        
        //If orientation doesn't match dimensions, correct the dimensions.  This happens when there are two orientation changes in quick succession.
        let orientation = UIDevice.current.orientation
        
        if UIDeviceOrientationIsPortrait(orientation) {
            
            //if the dimensions indicate landscape when it's really portrait
            if right > bottom {
                let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
                if isIpad || (!isIpad && orientation != UIDeviceOrientation.portraitUpsideDown) {
                    if portraitViewHeight != nil && portraitViewWidth != nil {
                        //Use the correctly stored dimensions
                        right = portraitViewWidth!
                        bottom = portraitViewHeight!
                    }
                }
            }
            else {
                //Store correct values for possible future use
                portraitViewHeight = bottom
                portraitViewWidth = right
            }
        }
        else if UIDeviceOrientationIsLandscape(orientation) {
            if right < bottom {
                if landscapeViewHeight != nil && landscapeViewWidth != nil {
                    //Use the correctly stored dimensions
                    right = landscapeViewWidth!
                    bottom = landscapeViewHeight!
                }
            }
            else {
                //Store correct values for possible future use
                landscapeViewHeight = bottom
                landscapeViewWidth = right
            }
        }
        
        tabBar.frame = CGRect(x: left, y: bottom, width: right - left, height: tabBarHeight)
    }
}