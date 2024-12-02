import 'package:flutter_native_contact_picker/model/contact.dart';

import 'flutter_native_contact_picker_platform_interface.dart';

class FlutterNativeContactPicker {
  Future<Contact?> selectContact({bool singlePhoneNumber = false}) async {
    // Call the platform interface and pass the parameter
    final contact = await FlutterNativeContactPickerPlatform.instance
        .selectContact(singlePhoneNumber: singlePhoneNumber);
    return contact;
  }

  Future<List<Contact>?> selectContacts() {
    return FlutterNativeContactPickerPlatform.instance.selectContacts();
  }
}
