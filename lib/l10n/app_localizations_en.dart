// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'POS Delivery';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get todaysDeliveries => 'Today\'s Deliveries';

  @override
  String get todaysSalesReturns => 'Today\'s Sales Returns';

  @override
  String get salesReturns => 'Sales Returns';

  @override
  String get categories => 'Categories';

  @override
  String get customers => 'Customers';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get newDelivery => 'New Delivery';

  @override
  String get createNewDelivery => 'Create a new delivery';

  @override
  String get salesReturn => 'Sales Return';

  @override
  String get recordSalesReturn => 'Record a sales return';

  @override
  String get sync => 'Sync';

  @override
  String get syncPendingData => 'Sync pending data';

  @override
  String get yourLocationIsBeingTracked => 'Your location is being tracked';

  @override
  String get pleaseStartDuty => 'Please start duty';

  @override
  String get startDuty => 'Start Duty';

  @override
  String get stopDuty => 'Stop Duty';

  @override
  String get syncNow => 'Sync Now';

  @override
  String syncNowPending(Object count) {
    return 'Sync Now ($count pending)';
  }

  @override
  String get noPendingDataToSync => 'No pending data to sync';

  @override
  String countPending(Object count) {
    return '$count pending';
  }

  @override
  String get addProducts => 'Add Products';

  @override
  String get editDelivery => 'Edit Delivery';

  @override
  String get invoice => 'Invoice';

  @override
  String get viewingCompletedInvoice => 'Viewing completed invoice';

  @override
  String get customer => 'Customer';

  @override
  String get items => 'Items';

  @override
  String get total => 'Total';

  @override
  String get all => 'All';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String get noProductsInCategory => 'No products in this category';

  @override
  String get selectCategoryToBrowse => 'Select a category to browse products';

  @override
  String get add => 'Add';

  @override
  String get addMore => 'Add more';

  @override
  String get inCart => 'In cart:';

  @override
  String get pleaseSelectItems => 'Please add items to continue';

  @override
  String get unknown => 'Unknown';

  @override
  String get qty => 'Qty';

  @override
  String get available => 'Available:';

  @override
  String get backToDelivery => 'Back to Delivery';

  @override
  String get noDeliveriesForToday => 'No deliveries for today';

  @override
  String get noSalesReturnsForToday => 'No sales returns for today';

  @override
  String get salesReturnDetail => 'Sales Return Detail';

  @override
  String salesReturnNumber(Object id) {
    return 'Sales Return #$id';
  }

  @override
  String get viewingSalesReturn => 'Viewing sales return';

  @override
  String get salesReturnNotFound => 'Sales return not found';

  @override
  String get syncInitiated => 'Sync initiated';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get cart => 'Cart';

  @override
  String get clear => 'Clear';

  @override
  String get cartIsEmpty => 'Cart is empty';

  @override
  String get continueLabel => 'Continue';

  @override
  String get lineTotal => 'Line Total';

  @override
  String get editPrice => 'Edit Price';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get customerLabel => 'Customer:';

  @override
  String get billing => 'Billing';

  @override
  String get invoiceSavedSuccessfully => 'Invoice Saved Successfully';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get grossAmount => 'Gross Amount';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get discountType => 'Discount Type';

  @override
  String get discountValue => 'Discount Value';

  @override
  String get none => 'None';

  @override
  String get amountRs => 'Amount (Rs.)';

  @override
  String get percent => 'Percent (%)';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get paymentMode => 'Payment Mode';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get remarksOptional => 'Remarks (Optional)';

  @override
  String get saving => 'Saving...';

  @override
  String get saveInvoice => 'Save Invoice';

  @override
  String get failedToSaveInvoice => 'Failed to save invoice';

  @override
  String get todaysEstimates => 'Today\'s Estimates';

  @override
  String get noEstimatesForToday => 'No estimates for today';

  @override
  String get goToSalesReturn => 'Go to Sales Return';

  @override
  String get goToDelivery => 'Go to Delivery';

  @override
  String get salesReturnSaved => 'Sales Return Saved';

  @override
  String get successfullyRecorded => 'Successfully recorded';

  @override
  String get newSalesReturn => 'New Sales Return';

  @override
  String get product => 'Product';

  @override
  String get products => 'Products';

  @override
  String get quantity => 'Quantity';

  @override
  String get additionalDetails => 'Additional Details';

  @override
  String get reason => 'Reason';

  @override
  String get saveSalesReturn => 'Save Sales Return';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get failedToSaveSalesReturn => 'Failed to save sales return';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get pending => 'Pending';

  @override
  String get failed => 'Failed';

  @override
  String get synced => 'Synced';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get never => 'Never';

  @override
  String get syncing => 'Syncing...';

  @override
  String get serverData => 'Server Data';

  @override
  String get syncAll => 'Sync All';

  @override
  String get syncCompletedSuccessfully => 'Sync completed successfully!';

  @override
  String get pendingItems => 'Pending Items';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get nepali => 'Nepali';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get delivery => 'Delivery';

  @override
  String deliveryNumber(Object id) {
    return 'Delivery #$id';
  }

  @override
  String get phone => 'Phone:';

  @override
  String get date => 'Date:';

  @override
  String get payment => 'Payment:';

  @override
  String get paid => 'Paid:';

  @override
  String qtyWithPrice(Object price, Object qty) {
    return 'Qty: $qty × Rs. $price';
  }

  @override
  String itemCount(Object count) {
    return '$count item';
  }

  @override
  String itemCountPlural(Object count) {
    return '$count items';
  }

  @override
  String customerId(Object id) {
    return 'Customer #$id';
  }

  @override
  String estimateNumber(Object id) {
    return 'Estimate #$id';
  }

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get deliveryShort => 'Delivery';

  @override
  String get receipt => 'Receipt';

  @override
  String get amount => 'Amount';

  @override
  String get remaining => 'Remaining:';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get makePayment => 'Make Payment';

  @override
  String get volumeDiscount => 'Volume Discount';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get done => 'Done';

  @override
  String get remove => 'Remove';

  @override
  String get change => 'Change';

  @override
  String get retry => 'Retry';

  @override
  String get selectCustomer => 'Select Customer';

  @override
  String get searchCustomer => 'Search customer...';

  @override
  String get changeCustomerTitle => 'Change customer?';

  @override
  String changeCustomerMessage(Object count) {
    return 'This will clear $count items already in the cart.';
  }

  @override
  String get clearAndContinue => 'Clear & continue';

  @override
  String get selectCategory => 'Select Category';

  @override
  String perUnit(Object unit) {
    return 'Per $unit';
  }

  @override
  String get unit => 'Unit';

  @override
  String get rate => 'Rate';

  @override
  String get value => 'Value';

  @override
  String get companyCode => 'Company Code';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get enterCompanyCode => 'Enter company code';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get selectCompany => 'Select Company';

  @override
  String get selectBranch => 'Select Branch';

  @override
  String get selectDepartment => 'Select Department';

  @override
  String get selectFiscalYear => 'Select Fiscal Year';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get productDiscount => 'Product Discount';

  @override
  String get noProductsAdded => 'No products added';

  @override
  String addedProducts(Object count) {
    return 'Added Products ($count)';
  }

  @override
  String get viewDetails => 'View details';

  @override
  String get noProductsAvailable => 'No products available';

  @override
  String get cartIsEmptyMessage =>
      'Cart is empty. Add products from the list above.';

  @override
  String cartItemCount(Object count) {
    return 'Cart ($count items)';
  }

  @override
  String get qtyLabel => 'Qty:';

  @override
  String get stock => 'Stock';

  @override
  String get posDelivery => 'POS Delivery';

  @override
  String get noCategoriesAvailable => 'No categories available';

  @override
  String get noCustomersAvailable => 'No customers available';

  @override
  String get searchProduct => 'Search Product';

  @override
  String get typeToSearch => 'Type to search...';

  @override
  String get noProductsFound => 'No products found';

  @override
  String billsPendingSync(Object count) {
    return '$count bill(s) pending sync';
  }

  @override
  String get offlineInvoicesWaiting =>
      'Offline invoices waiting to be pushed to server.';

  @override
  String get deliveryLabel => 'Delivery';

  @override
  String invoiceNumber(Object id) {
    return 'Invoice #$id';
  }

  @override
  String get pleaseMakeFullPayment => 'Please make full payment';

  @override
  String get pleaseEnterReason => 'Please add return reason';

  @override
  String get pleaseEnterPaymode => 'Please add payment entry';

  @override
  String get preferences => 'preferences';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get addNewCustomer => 'Add New Customer';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerMobile => 'Mobile';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get discountGroup => 'Discount Group';

  @override
  String get selectDiscountGroup => 'Select discount group';

  @override
  String get enterCustomerName => 'Please enter customer name';

  @override
  String get enterCustomerMobile => 'Please enter mobile number';

  @override
  String get selectDiscountGroupRequired => 'Please select a discount group';

  @override
  String get customerAddedSuccessfully => 'Customer added successfully';

  @override
  String get customerUpdatedSuccessfully => 'Customer updated successfully';

  @override
  String get failedToAddCustomer => 'Failed to add customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get manageCustomers => 'View and manage customers';

  @override
  String get pan => 'PAN';

  @override
  String get needInternetToSaveCustomer =>
      'An internet connection is required to add or edit a customer.';

  @override
  String get customerMobileAlreadyExists =>
      'A customer with this mobile number already exists.';

  @override
  String get customerSyncStatus => 'Customer Sync Status';

  @override
  String get notSynced => 'Not synced';

  @override
  String get noCustomerSyncEntries => 'No customers pending sync.';
}
