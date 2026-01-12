class ApiConstants {
  // 10.0.2.2 is localhost for Android Emulator
  // If using a real device, change this to your PC's IP (e.g., http://192.168.1.15:8000/api)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user'; 

  // Core Data
  static const String profiles = '/profiles';
  static const String products = '/products';
  static const String employees = '/employees';
  static const String expenses = '/expenses';
  static const String expenseCategories = '/expense_categories';
  static const String withdrawals = '/owner_withdrawals';
  static const String sales = '/sales';

  // RPC / Custom Actions
  static const String setManagerPassword = '/rpc/set_manager_password';
  static const String verifyManagerPassword = '/rpc/verify_manager_password';
  static const String isManagerPasswordSet = '/rpc/is_manager_password_set';
  
  static const String createSale = '/rpc/create_sale_and_update_inventory';
  static const String getSaleDetails = '/rpc/get_sale_details';
  static const String processReturn = '/rpc/process_return';
  static const String processExchange = '/rpc/process_exchange';
  
  static const String financialSummary = '/rpc/get_financial_summary';
}