import Foundation
import UIKit
import WeechatRelay

public class WeechatLineFormatter {
    
    static let lockQueue = dispatch_queue_create("weechatformatter", nil)
    
    static var message: NSString!
    static var currentLine: NSString!
    static var attributedString: NSMutableAttributedString!
    static var attributes: [String: AnyObject]!
    static var lineIndex = 0
    
    static var regex: NSRegularExpression!
    
    public static func formatWeechatLine(message: String) -> NSAttributedString {
        dispatch_sync(lockQueue) {
            self.message = message
            self.attributedString = NSMutableAttributedString()
            self.attributes = Dictionary()
            
            if self.regex == nil {
                do {
                    self.regex = try NSRegularExpression(
                        pattern: "(\\x19|\\x1a|\\x1b|\\x1c)([^\\x19\\x1a\\x1b\\x1c]+)",
                        options: [])
                } catch {
                    print("regex failed to be initialized")
                }
            }
            
            let matches = self.regex.matchesInString(
                self.message as String,
                options: [],
                range: NSMakeRange(0, self.message.length))
            
            for match in matches {
                if match.numberOfRanges > 2 {
                    parseColorLine(match)
                }
            }
            
            if self.attributedString.length == 0 {
                self.attributedString.appendAttributedString(NSAttributedString(string: self.message as String))
            }
        }
        return self.attributedString.copy() as! NSAttributedString
    }
    
    private static func parseColorLine(match: NSTextCheckingResult) {
        self.lineIndex = 0
        let ctrlChar = self.message.substringWithRange(match.rangeAtIndex(1))
        // printFirstCharAsHex(ctrlChar)
        self.currentLine = self.message.substringWithRange(match.rangeAtIndex(2)) as NSString
        // print(self.currentLine)
        
        if self.currentLine.hasPrefix("F") {
            self.lineIndex++
        }
        if self.currentLine.hasPrefix("*")
            || self.currentLine.hasPrefix("!")
            || self.currentLine.hasPrefix("/")
            || self.currentLine.hasPrefix("_")
            || self.currentLine.hasPrefix("|") {
                
            self.lineIndex++
                
            // debugPrint(readStandardColorValue())
            setForegroundColor()
            self.lineIndex++ // skip the comma
            setBackgroundColor()
        } else {
            // debugPrint(readStandardColorValue())
            setForegroundColor()
        }
        
        // print(self.currentLine.substringFromIndex(lineIndex), lineIndex)
        attributedString.appendAttributedString(NSAttributedString(string: self.currentLine.substringFromIndex(lineIndex), attributes: attributes))
        
    }
    
    static func setForegroundColor() {
        if let color = getColor() {
            attributes[NSForegroundColorAttributeName] = color
        } else {
            attributes.removeValueForKey(NSForegroundColorAttributeName)
        }
    }
    
    static func setBackgroundColor() {
        if let color = getColor() {
            attributes[NSBackgroundColorAttributeName] = color
        } else {
            attributes.removeValueForKey(NSBackgroundColorAttributeName)
        }
    }
    
    static func getColor() -> UIColor? {
        if isExtendedColorValue() {
            self.lineIndex += 1
            return getExtendedColor()
        } else {
            return getStandardColor()
        }
    }
    
    static func getStandardColor() -> UIColor? {
        if let colorValue = readStandardColorValue() where colorValue != 0 {
            self.lineIndex += 2
            return colorsDict[colorValue]
        } else {
            return nil
        }
    }
    
    static func getExtendedColor() -> UIColor? {
        guard let colorValue = readExtendedColorValue() else { return nil }
        self.lineIndex += 5
        if colorValue <= 16 {
            return colorsDict[colorValue]
        }
        
        let base: [UInt8] = [0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF]
        
        let j = colorValue - 16
        
        return UIColor(red: CGFloat(base[(j / 36) % 6]) / CGFloat(255),
                     green: CGFloat(base[(j / 6) % 6]) / CGFloat(255),
                      blue: CGFloat(base[j % 6]) / CGFloat(255),
                     alpha: 1)
        
    }
    
    static func readStandardColorValue() -> Int? {
        return Int(self.currentLine.substringWithRange(NSMakeRange(self.lineIndex, 2)))
    }
    
    static func isExtendedColorValue() -> Bool {
        return self.currentLine.substringWithRange(NSMakeRange(self.lineIndex, 1)) == "@"
    }
    
    static func readExtendedColorValue() -> Int? {
        return Int(self.currentLine.substringWithRange(NSMakeRange(self.lineIndex, 5)))
    }
    
    static func printFirstCharAsHex(string: String) {
        print(String(format:"0x%2X", string.unicodeScalars.first!.value))
    }
    
    static let colorsDict = [
        0: UIColor.fromHex("#000000"), // Black
        1: UIColor.fromHex("#000000"), // Black
        2: UIColor.fromHex("#808080"), // Gray
        3: UIColor.fromHex("#FF0000"), // Red
        4: UIColor.fromHex("#800000"), // Light Red
        5: UIColor.fromHex("#00FF00"), // Green
        6: UIColor.fromHex("#008000"), // Light Green
        7: UIColor.fromHex("#808000"), // Light Yellow(Brown)
        8: UIColor.fromHex("#FFFF00"), // Yellow
        9: UIColor.fromHex("#0000FF"), // Blue
        10: UIColor.fromHex("#000080"), // Light Blue
        11: UIColor.fromHex("#FF00FF"), // Magenta
        12: UIColor.fromHex("#800080"), // Light Magenta
        13: UIColor.fromHex("#00FFFF"), // Cyan
        14: UIColor.fromHex("#008080"), // Light Cyan
        15: UIColor.fromHex("#C0C0C0"), // Light Gray
        16: UIColor.fromHex("#FFFFFF") // White
    ]
}


extension UIColor {
    static func fromHex(hexString: String) -> UIColor {
        var rgbValue: UInt32 = 0
        let scanner = NSScanner(string: hexString)
        scanner.scanLocation = 1 // bypass '#' character
        scanner.scanHexInt(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgbValue & 0xFF00) >> 8)/255.0,
            blue: CGFloat(rgbValue & 0xFF)/255.0,
            alpha: 1.0)
    }
}