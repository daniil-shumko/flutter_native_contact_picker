import Flutter
import UIKit
import ContactsUI


public class FlutterNativeContactPickerPlugin: NSObject, FlutterPlugin, CNContactPickerDelegate {
  var _delegate: PickerHandler?;

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_contact_picker", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeContactPickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
   if("selectContact" == call.method || "selectContacts" == call.method) {
    
        if(_delegate != nil) {
            _delegate!.result(FlutterError(code: "multiple_requests", message: "Cancelled by a second request.", details: nil));
            _delegate = nil;
          }

          if #available(iOS 9.0, *){
              let single = call.method == "selectContact";
              let args = call.arguments as? [String: Any];
              let singlePhoneNumber = (args?["singlePhoneNumber"] as? Bool) ?? false;
              _delegate = single ? SinglePickerHandler(result: result, singlePhoneNumber: singlePhoneNumber) : MultiPickerHandler(result: result);
              let contactPicker = CNContactPickerViewController()
              contactPicker.delegate = _delegate
              contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
              
              // find proper keyWindow
              var keyWindow: UIWindow? = nil
              if #available(iOS 13, *) {
                  keyWindow = UIApplication.shared.connectedScenes.filter {
                      $0.activationState == .foregroundActive
                  }.compactMap { $0 as? UIWindowScene
                  }.first?.windows.filter({ $0.isKeyWindow}).first
              } else {
                  keyWindow = UIApplication.shared.keyWindow
              }
              
              let viewController = keyWindow?.rootViewController
              viewController?.present(contactPicker, animated: true, completion: nil)
          }
      }
       else
          {
              result(FlutterMethodNotImplemented)
          }
    
  }
}

class PickerHandler: NSObject, CNContactPickerDelegate  {
    var result: FlutterResult;
    
    required init(result: @escaping FlutterResult) {
        self.result = result
        super.init()
    }
    
    
    @available(iOS 9.0, *)
    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        result(nil)
    }
}

class SinglePickerHandler: PickerHandler {
    let singlePhoneNumber: Bool
    
    required init(result: @escaping FlutterResult, singlePhoneNumber: Bool) {
        self.singlePhoneNumber = singlePhoneNumber
        super.init(result: result)
    }
    
    @available(iOS 9.0, *)
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        if contactProperty.key == CNContactPhoneNumbersKey,
           let phoneNumberValue = contactProperty.value as? CNPhoneNumber {
            var data = Dictionary<String, Any>()
            let contact = contactProperty.contact
            data["fullName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
            
            if singlePhoneNumber {
                data["phoneNumbers"] = [phoneNumberValue.stringValue]
            } else {
                let numbers: [String] = contact.phoneNumbers.compactMap { $0.value.stringValue }
                data["phoneNumbers"] = numbers
            }
            data["selectedPhoneNumber"] = phoneNumberValue.stringValue
            result(data)
        }
    }
}

class MultiPickerHandler: PickerHandler {
    @available(iOS 9.0, *)
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        var selectedContacts = [Dictionary<String, Any>]()

         for contact in contacts {
             var contactInfo = Dictionary<String, Any>()
             contactInfo["fullName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)

             let numbers: [String] = contact.phoneNumbers.compactMap { $0.value.stringValue as String }
             contactInfo["phoneNumbers"] = numbers

             selectedContacts.append(contactInfo)
         }

         result(selectedContacts)
    }
}
