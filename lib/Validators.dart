class Validators {
  static String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (RegExp(r'^[0-9]').hasMatch(password)) {
      return 'Password must not start with a number';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain letters';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain numbers';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain special characters';
    }
    return null;
  }

  static List<String> passwordUnmetConstraints(String password) {
    final List<String> unmet = [];
    if (password.length < 8) {
      unmet.add('At least 8 characters');
    }
    if (RegExp(r'^[0-9]').hasMatch(password)) {
      unmet.add('Does not start with a number');
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      unmet.add('Contains letters');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      unmet.add('Contains numbers');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      unmet.add('Contains special characters');
    }
    return unmet;
  }
}