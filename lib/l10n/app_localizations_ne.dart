// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'POS डेलिभरी';

  @override
  String get dashboard => 'ड्यासबोर्ड';

  @override
  String get online => 'अनलाइन';

  @override
  String get offline => 'अफलाइन';

  @override
  String get welcomeBack => 'फेरि स्वागत छ,';

  @override
  String get todaysDeliveries => 'आजको डेलिभरीहरू';

  @override
  String get todaysSalesReturns => 'आजको सेल्स रिटर्नहरू';

  @override
  String get salesReturns => 'सेल्स रिटर्न';

  @override
  String get categories => 'कोटिहरू';

  @override
  String get customers => 'ग्राहकहरू';

  @override
  String get quickActions => 'द्रुत कार्यहरू';

  @override
  String get newDelivery => 'नयाँ डेलिभरी';

  @override
  String get createNewDelivery => 'नयाँ डेलिभरी सिर्जना गर्नुहोस्';

  @override
  String get salesReturn => 'सेल्स रिटर्न';

  @override
  String get recordSalesReturn => 'सेल्स रिटर्न रेकर्ड गर्नुहोस्';

  @override
  String get sync => 'सिङ्क';

  @override
  String get syncPendingData => 'पेन्डिङ डेटा सिङ्क गर्नुहोस्';

  @override
  String get yourLocationIsBeingTracked => 'तपाईंको स्थान ट्र्याक गरिँदैछ';

  @override
  String get pleaseStartDuty => 'कृपया ड्युटी सुरु गर्नुहोस्';

  @override
  String get startDuty => 'ड्युटी सुरु गर्नुहोस्';

  @override
  String get stopDuty => 'ड्युटी बन्द गर्नुहोस्';

  @override
  String get syncNow => 'अहिले सिङ्क गर्नुहोस्';

  @override
  String syncNowPending(Object count) {
    return 'अहिले सिङ्क गर्नुहोस् ($count पेन्डिङ)';
  }

  @override
  String get noPendingDataToSync => 'सिङ्क गर्न पेन्डिङ डेटा छैन';

  @override
  String countPending(Object count) {
    return '$count पेन्डिङ';
  }

  @override
  String get addProducts => 'उत्पादनहरू थप्नुहोस्';

  @override
  String get editDelivery => 'डेलिभरी सम्पादन गर्नुहोस्';

  @override
  String get invoice => 'इन्भ्वाइस';

  @override
  String get viewingCompletedInvoice => 'पूरा भएको इन्भ्वाइस हेर्दै';

  @override
  String get customer => 'ग्राहक';

  @override
  String get items => 'वस्तुहरू';

  @override
  String get total => 'जम्मा';

  @override
  String get all => 'सबै';

  @override
  String get searchProducts => 'उत्पादनहरू खोज्नुहोस्...';

  @override
  String get clearFilter => 'फिल्टर हटाउनुहोस्';

  @override
  String get noProductsInCategory => 'यस कोटीमा कुनै उत्पादन छैन';

  @override
  String get selectCategoryToBrowse => 'उत्पादनहरू हेर्न कोटी चयन गर्नुहोस्';

  @override
  String get add => 'थप्नुहोस्';

  @override
  String get addMore => 'थप थप्नुहोस्';

  @override
  String get inCart => 'कार्टमा:';

  @override
  String get pleaseSelectItems => 'कृपया वस्तुहरू थप्नुहोस्';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get qty => 'मात्रा';

  @override
  String get available => 'उपलब्ध:';

  @override
  String get backToDelivery => 'डेलिभरीमा फर्कनुहोस्';

  @override
  String get noDeliveriesForToday => 'आजको लागि कुनै डेलिभरी छैन';

  @override
  String get noSalesReturnsForToday => 'आजको लागि कुनै सेल्स रिटर्न छैन';

  @override
  String get salesReturnDetail => 'सेल्स रिटर्न विवरण';

  @override
  String salesReturnNumber(Object id) {
    return 'सेल्स रिटर्न #$id';
  }

  @override
  String get viewingSalesReturn => 'सेल्स रिटर्न हेर्दै';

  @override
  String get salesReturnNotFound => 'सेल्स रिटर्न फेला परेन';

  @override
  String get syncInitiated => 'सिङ्क सुरु भयो';

  @override
  String get syncFailed => 'सिङ्क असफल भयो';

  @override
  String get cart => 'कार्ट';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get cartIsEmpty => 'कार्ट खाली छ';

  @override
  String get continueLabel => 'जारी राख्नुहोस्';

  @override
  String get lineTotal => 'लाइन जम्मा';

  @override
  String get editPrice => 'मूल्य सम्पादन गर्नुहोस्';

  @override
  String get unitPrice => 'एकाइ मूल्य';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get save => 'सुरक्षित गर्नुहोस्';

  @override
  String get customerLabel => 'ग्राहक:';

  @override
  String get billing => 'बिलिङ';

  @override
  String get invoiceSavedSuccessfully => 'इन्भ्वाइस सफलतापूर्वक सुरक्षित भयो';

  @override
  String get backToDashboard => 'ड्यासबोर्डमा फर्कनुहोस्';

  @override
  String get grossAmount => 'कुल रकम';

  @override
  String get tax => 'कर';

  @override
  String get discount => 'छुट';

  @override
  String get discountType => 'छुट प्रकार';

  @override
  String get discountValue => 'छुट मूल्य';

  @override
  String get none => 'कुनै पनि होइन';

  @override
  String get amountRs => 'रकम (रु.)';

  @override
  String get percent => 'प्रतिशत (%)';

  @override
  String get totalAmount => 'जम्मा रकम';

  @override
  String get paymentDetails => 'भुक्तानी विवरण';

  @override
  String get paymentMode => 'भुक्तानी मोड';

  @override
  String get paidAmount => 'भुक्तान गरिएको रकम';

  @override
  String get remarksOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get saving => 'सुरक्षित गरिँदै...';

  @override
  String get saveInvoice => 'इन्भ्वाइस सुरक्षित गर्नुहोस्';

  @override
  String get failedToSaveInvoice => 'इन्भ्वाइस सुरक्षित गर्न असफल भयो';

  @override
  String get todaysEstimates => 'आजको अनुमानहरू';

  @override
  String get noEstimatesForToday => 'आजको लागि कुनै अनुमान छैन';

  @override
  String get goToSalesReturn => 'सेल्स रिटर्नमा जानुहोस्';

  @override
  String get goToDelivery => 'डेलिभरीमा जानुहोस्';

  @override
  String get salesReturnSaved => 'सेल्स रिटर्न सुरक्षित भयो';

  @override
  String get successfullyRecorded => 'सफलतापूर्वक रेकर्ड गरियो';

  @override
  String get newSalesReturn => 'नयाँ सेल्स रिटर्न';

  @override
  String get product => 'उत्पादन';

  @override
  String get products => 'उत्पादनहरू';

  @override
  String get quantity => 'मात्रा';

  @override
  String get additionalDetails => 'अतिरिक्त विवरण';

  @override
  String get reason => 'कारण';

  @override
  String get saveSalesReturn => 'सेल्स रिटर्न सुरक्षित गर्नुहोस्';

  @override
  String get selectProduct => 'उत्पादन चयन गर्नुहोस्';

  @override
  String get failedToSaveSalesReturn => 'सेल्स रिटर्न सुरक्षित गर्न असफल भयो';

  @override
  String get syncStatus => 'सिङ्क स्थिति';

  @override
  String get pending => 'पेन्डिङ';

  @override
  String get failed => 'असफल';

  @override
  String get synced => 'सिङ्क गरिएको';

  @override
  String get lastSync => 'अन्तिम सिङ्क';

  @override
  String get never => 'कहिल्यै पनि होइन';

  @override
  String get syncing => 'सिङ्क गरिँदै...';

  @override
  String get serverData => 'सर्भर डेटा';

  @override
  String get syncAll => 'सबै सिङ्क गर्नुहोस्';

  @override
  String get syncCompletedSuccessfully => 'सिङ्क सफलतापूर्वक पूरा भयो!';

  @override
  String get pendingItems => 'पेन्डिङ वस्तुहरू';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अङ्ग्रेजी';

  @override
  String get nepali => 'नेपाली';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get on => 'अन';

  @override
  String get off => 'अफ';

  @override
  String get delivery => 'डेलिभरी';

  @override
  String deliveryNumber(Object id) {
    return 'डेलिभरी #$id';
  }

  @override
  String get phone => 'फोन:';

  @override
  String get date => 'मिति:';

  @override
  String get payment => 'भुक्तानी:';

  @override
  String get paid => 'भुक्तान गरिएको:';

  @override
  String qtyWithPrice(Object price, Object qty) {
    return 'मात्रा: $qty × रु. $price';
  }

  @override
  String itemCount(Object count) {
    return '$count वस्तु';
  }

  @override
  String itemCountPlural(Object count) {
    return '$count वस्तुहरू';
  }

  @override
  String customerId(Object id) {
    return 'ग्राहक #$id';
  }

  @override
  String estimateNumber(Object id) {
    return 'अनुमान #$id';
  }

  @override
  String statusLabel(Object status) {
    return 'स्थिति: $status';
  }

  @override
  String get deliveryShort => 'डेलिभरी';

  @override
  String get receipt => 'रसिद';

  @override
  String get amount => 'रकम';

  @override
  String get remaining => 'बाँकी:';

  @override
  String get addPayment => 'भुक्तानी थप्नुहोस्';

  @override
  String get makePayment => 'भुक्तानी गर्नुहोस्';

  @override
  String get volumeDiscount => 'भोल्युम छुट';

  @override
  String get logout => 'लग आउट';

  @override
  String get confirmLogout => 'के तपाईं लग आउट गर्न चाहनुहुन्छ?';

  @override
  String get done => 'भयो';

  @override
  String get remove => 'हटाउनुहोस्';

  @override
  String get change => 'परिवर्तन गर्नुहोस्';

  @override
  String get retry => 'पुन: प्रयास गर्नुहोस्';

  @override
  String get selectCustomer => 'ग्राहक चयन गर्नुहोस्';

  @override
  String get searchCustomer => 'ग्राहक खोज्नुहोस्...';

  @override
  String get changeCustomerTitle => 'ग्राहक परिवर्तन गर्नुहोस्?';

  @override
  String changeCustomerMessage(Object count) {
    return 'यसले कार्टमा रहेका $count वस्तुहरू हटाउनेछ।';
  }

  @override
  String get clearAndContinue => 'हटाएर जारी राख्नुहोस्';

  @override
  String get selectCategory => 'कोटी चयन गर्नुहोस्';

  @override
  String perUnit(Object unit) {
    return 'प्रति $unit';
  }

  @override
  String get unit => 'एकाइ';

  @override
  String get rate => 'दर';

  @override
  String get value => 'मूल्य';

  @override
  String get companyCode => 'कम्पनी कोड';

  @override
  String get username => 'प्रयोगकर्ता नाम';

  @override
  String get password => 'पासवर्ड';

  @override
  String get login => 'लग इन';

  @override
  String get enterCompanyCode => 'कम्पनी कोड प्रविष्ट गर्नुहोस्';

  @override
  String get enterUsername => 'प्रयोगकर्ता नाम प्रविष्ट गर्नुहोस्';

  @override
  String get enterPassword => 'पासवर्ड प्रविष्ट गर्नुहोस्';

  @override
  String get selectCompany => 'कम्पनी चयन गर्नुहोस्';

  @override
  String get selectBranch => 'शाखा चयन गर्नुहोस्';

  @override
  String get selectDepartment => 'विभाग चयन गर्नुहोस्';

  @override
  String get selectFiscalYear => 'आर्थिक वर्ष चयन गर्नुहोस्';

  @override
  String get noCustomersFound => 'कुनै ग्राहक फेला भएन';

  @override
  String get productDiscount => 'उत्पादन छुट';

  @override
  String get noProductsAdded => 'कुनै उत्पादन थपिएको छैन';

  @override
  String addedProducts(Object count) {
    return 'थपिएका उत्पादनहरू ($count)';
  }

  @override
  String get viewDetails => 'विवरण हेर्नुहोस्';

  @override
  String get noProductsAvailable => 'कुनै उत्पादन उपलब्ध छैन';

  @override
  String get cartIsEmptyMessage =>
      'कार्ट खाली छ। माथिको सूचीबाट उत्पादनहरू थप्नुहोस्।';

  @override
  String cartItemCount(Object count) {
    return 'कार्ट ($count वस्तुहरू)';
  }

  @override
  String get qtyLabel => 'मात्रा:';

  @override
  String get stock => 'स्टक';

  @override
  String get posDelivery => 'POS डेलिभरी';

  @override
  String get noCategoriesAvailable => 'कुनै कोटी उपलब्ध छैन';

  @override
  String get noCustomersAvailable => 'कुनै ग्राहक उपलब्ध छैन';

  @override
  String get searchProduct => 'उत्पादन खोज्नुहोस्';

  @override
  String get typeToSearch => 'खोज्न टाइप गर्नुहोस्...';

  @override
  String get noProductsFound => 'कुनै उत्पादन फेला भएन';

  @override
  String billsPendingSync(Object count) {
    return '$count बिल(हरू) सिङ्क पेन्डिङ';
  }

  @override
  String get offlineInvoicesWaiting =>
      'अफलाइन इन्भ्वाइसहरू सर्भरमा पठाउन बाँकी छन्।';

  @override
  String get deliveryLabel => 'डेलिभरी';

  @override
  String invoiceNumber(Object id) {
    return 'इन्भ्वाइस #$id';
  }

  @override
  String get pleaseMakeFullPayment => 'कृपया पूरा भुक्तानी गर्नुहोस्';

  @override
  String get pleaseEnterReason => 'कृपया रिटर्न कारण थप्नुहोस्';

  @override
  String get pleaseEnterPaymode => 'कृपया भुक्तानी मोड थप्नुहोस्';

  @override
  String get preferences => 'प्राथमिकता';

  @override
  String get addCustomer => 'ग्राहक थप्नुहोस्';

  @override
  String get addNewCustomer => 'नयाँ ग्राहक थप्नुहोस्';

  @override
  String get customerName => 'ग्राहकको नाम';

  @override
  String get customerMobile => 'मोबाइल';

  @override
  String get email => 'इमेल';

  @override
  String get address => 'ठेगाना';

  @override
  String get discountGroup => 'छुट समूह';

  @override
  String get selectDiscountGroup => 'छुट समूह चयन गर्नुहोस्';

  @override
  String get enterCustomerName => 'कृपया ग्राहकको नाम लेख्नुहोस्';

  @override
  String get enterCustomerMobile => 'कृपया मोबाइल नम्बर लेख्नुहोस्';

  @override
  String get selectDiscountGroupRequired => 'कृपया छुट समूह चयन गर्नुहोस्';

  @override
  String get customerAddedSuccessfully => 'ग्राहक सफलतापूर्वक थपियो';

  @override
  String get customerUpdatedSuccessfully =>
      'ग्राहक सफलतापूर्वक अद्यावधिक गरियो';

  @override
  String get failedToAddCustomer => 'ग्राहक थप्न असफल भयो';

  @override
  String get editCustomer => 'ग्राहक सम्पादन गर्नुहोस्';

  @override
  String get manageCustomers => 'ग्राहकहरू हेर्नुहोस् र व्यवस्थापन गर्नुहोस्';

  @override
  String get pan => 'प्यान';

  @override
  String get needInternetToSaveCustomer =>
      'ग्राहक थप्न वा सम्पादन गर्न इन्टरनेट जडान आवश्यक छ।';

  @override
  String get customerMobileAlreadyExists =>
      'यो मोबाइल नम्बर भएको ग्राहक पहिले नै अवस्थित छ।';

  @override
  String get customerSyncStatus => 'ग्राहक सिङ्क स्थिति';

  @override
  String get notSynced => 'सिङ्क नगरिएको';

  @override
  String get noCustomerSyncEntries => 'सिङ्क हुन बाँकी कुनै ग्राहक छैन।';
}
