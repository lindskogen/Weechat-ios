import Foundation
import WeechatRelay
import SSHPortForward
import ReactiveCocoa

public class WeechatConnection: NSObject, SSHConnectionDelegate, WeechatMessageHandlerDelegate {
    
    public static let sharedInstance = WeechatConnection()
    
    var weechat: Weechat!
    var bufferManager = WeechatBufferManager()
    var lineManager: WeechatLineManager
    
    var bufferDelegate: BufferDelegate?
    
    var host: String!
    var port: Int!
    var ssh_port: Int!
    
    override private init() {
        lineManager = WeechatLineManager(bufferManager: bufferManager)
        
        super.init()
        
        bufferManager.delegate = self
        
        SSHTunnel.setDelegate(self)
    }
    
    public func portDidOpen(port: Int32) {
        let host = "127.0.0.1"
        connect(host, port: Int(port))
    }
    
    public func subscribe() -> RACSignal {
        return RACSignal.createSignal { subscriber in
            subscriber.sendNext(6)
            return nil
        }
    }
    
    public func didUpdateData() {
        bufferDelegate?.buffersDidUpdate()
    }
    
    public func connect(host: String, port: Int = 9000) {
        do {
            weechat = try Weechat(host: host, port: port)
            onConnected()
        } catch {
            print("weechat could not connect to \(host):\(port)")
        }
    }
    
    public func connectTestSSH() {
        let ip = ""
        let user = ""
        let password = ""
        connectSSH(ip, user: user, password: password, port: 9000, ssh_port: 22)
    }
    
    public func connectSSH(host: String, user: String, password: String, port: Int = 9000, ssh_port: Int = 22) {
        SSHTunnel.host = host
        SSHTunnel.user = user
        SSHTunnel.password = password
        SSHTunnel.port = Int32(port)
        SSHTunnel.ssh_port = Int32(ssh_port)
        
        SSHTunnel.runThread()
    }
    
    func onConnected() {
        weechat.addHandler(WeechatTagConstant.BUFFER.rawValue, handler: bufferManager)
        weechat.addHandler(WeechatTagConstant.LINES.rawValue, handler: lineManager)
        weechat.getBuffers()
        weechat.getLines(40)
    }
    
    func buffers() -> [WeechatBuffer] {
        let dict = bufferManager.buffers as NSDictionary
        
        return (dict.allValues as! [WeechatBuffer]).sort({ (buffer1, buffer2) -> Bool in
            return buffer2.number > buffer1.number
        })
    }
}


protocol BufferDelegate {
    func buffersDidUpdate()
}











