class TransactionStatusResponse {
  final bool success;
  final String message;
  final int state; // 0 = Processing, 1 = Success, 2 = Failed

  TransactionStatusResponse({
    required this.success,
    required this.message,
    required this.state,
  });

  factory TransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    final status = json['Status'] as bool? ?? false;
    final message = (json['Message'] ?? '').toString();
    final data = json['Data'];

    int state;
    if (status && data == null) {
      // Server returns Status:true + null Data when still processing
      state = 0;
    } else if (status) {
      state = 1;
    } else {
      state = 2;
    }

    return TransactionStatusResponse(
      success: status,
      message: message,
      state: state,
    );
  }
}
