import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingopanda_assignment/screens/home_screen.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Add loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: _buildLoginForm(context),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'e-Shop',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFF0C54BE),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white10,
      elevation: 0,
      toolbarHeight: 60,
    );
  }

  Column _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 200),
        _isLoading // Check loading state
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C54BE)), // Set the color
              ) // Show loading indicator if true
            : _buildLoginButton(context), // Show login button if not loading
        const SizedBox(height: 20),
        _buildSignUpRow(context),
      ],
    );
  }

  TextField _buildEmailField() {
    return TextField(
      controller: emailController,
      decoration: _inputDecoration('Email'),
      style: TextStyle(fontFamily: 'Poppins'),
    );
  }

  TextField _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: _togglePasswordVisibility,
        ),
      ),
      style: TextStyle(fontFamily: 'Poppins'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  ElevatedButton _buildLoginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _login(context),
      child: const Text('Login', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0C54BE),
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Row _buildSignUpRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New here?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToSignUp(context),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF0C54BE),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _login(BuildContext context) async {
    // Check if fields are empty before continuing
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(e);
    } catch (e) {
      print("Login failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred.")),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  void _showErrorMessage(FirebaseAuthException e) {
    String message = _getErrorMessage(e);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return "Wrong email or password.";
      case 'invalid-email':
        return "Invalid email format.";
      default:
        return "Login failed. Please try again.";
    }
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupPage()),
    );
  }
}
