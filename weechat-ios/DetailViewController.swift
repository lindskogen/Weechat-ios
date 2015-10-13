import UIKit
import WeechatRelay

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var scrollTableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    
    var lines: [WeechatBufferLine] = []
    var formattedLines = [Int: NSAttributedString]()
    
    var detailItem: WeechatBuffer? {
        didSet {
            if let buffer = detailItem {
                lines = buffer.lines
                formattedLines.removeAll(keepCapacity: true)
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lines.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TitleTableCell", forIndexPath: indexPath) as! BufferLineCell
        
        let line = self.lines[indexPath.row]
        
        let dateString = NSDateFormatter.localizedStringFromDate(line.date, dateStyle: .NoStyle, timeStyle: .ShortStyle)
        
        var metaString = dateString
        
        if let nickIndex = line.tags.indexOf({ $0 != nil && $0!.hasPrefix("nick_") }) {
            let nick = (line.tags[nickIndex]! as NSString).substringFromIndex(5)
            
            metaString = nick
        }
        
        cell.metaDataLabel?.text = metaString
        
        cell.messageLabel?.attributedText = formattedString(line)
        
        return cell
    }
    
    func formattedString(line: WeechatBufferLine) -> NSAttributedString {
        var message = self.formattedLines[line.pointer]
        if message == nil {
            message = WeechatLineFormatter.formatWeechatLine(line.message)
            self.formattedLines[line.pointer] = message!
        }
        return message!
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let value = textField.text {
            print(value)
            textField.text = ""
        }
        return false
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        // animateTextField(textField, up: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // animateTextField(textField, up: false)
    }
    
    func animateTextField(textField: UITextField, up: Bool) {
        let movementDistance = 215 // tweak as needed
        let movementDuration = 0.3 // tweak as needed
        
        let movement = (up ? -movementDistance : movementDistance)
        
        UIView.beginAnimations("anim", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        
        self.view.frame = CGRectOffset(self.view.frame, 0, CGFloat(movement))
        
        UIView.commitAnimations()
    }
    
    func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return action == Selector("copy:");
    }
    
    func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if action == Selector("copy:") {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! BufferLineCell
            UIPasteboard.generalPasteboard().string = cell.messageLabel.text
        }
    }
    
    @IBAction func longPressedLine(longPress: UILongPressGestureRecognizer) {
        if longPress.state == .Began {
            let pos = longPress.locationInView(self.scrollTableView)
            if let indexPath = self.scrollTableView.indexPathForRowAtPoint(pos) {
                let cell = self.scrollTableView.cellForRowAtIndexPath(indexPath)!
                
                UIMenuController.sharedMenuController().setTargetRect(cell.frame, inView: self.view)
                UIMenuController.sharedMenuController().setMenuVisible(true, animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("longPressedLine:"))
        
        scrollTableView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if scrollTableView.contentSize.height > UIScreen.mainScreen().bounds.height {
            scrollTableView.contentOffset.y = scrollTableView.contentSize.height - UIScreen.mainScreen().bounds.height
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

