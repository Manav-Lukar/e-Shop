import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lingopanda_assignment/screens/home_screen.dart';
import 'login_page.dart'; // import the login page

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Added loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Adjust for keyboard
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: SizedBox()), // Flexible space
                      _buildSignupForm(context),
                      Expanded(child: SizedBox()), // Flexible space to prevent overflow
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
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

  Column _buildSignupForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTextField(nameController, 'Name'),
        const SizedBox(height: 16),
        _buildTextField(emailController, 'Email'),
        const SizedBox(height: 16),
        _buildPasswordField(),
        const SizedBox(height: 50), // Adjusted space to handle overflow
        _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0C54BE)), // Set the color
              ) // Show loading spinner when signing up
            : _buildSignupButton(context), // Show button otherwise
        const SizedBox(height: 20),
        _buildLoginRow(context), // Added Login row here
      ],
    );
  }

  TextField _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: const TextStyle(fontFamily: 'Poppins'),
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
      style: const TextStyle(fontFamily: 'Poppins'),
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

  ElevatedButton _buildSignupButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => signup(context),
      child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0C54BE),
        padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // New Row for Login link
  Row _buildLoginRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          ),
          child: const Text(
            'Login',
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

  // Show loading state when signup is in progress
  void signup(BuildContext context) async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Set user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nameController.text,
        'email': emailController.text,
      });

      // Clear fields and show success message immediately
      nameController.clear();
      emailController.clear();
      passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup successful!")),
      );

      // Navigate to HomeScreen after a brief delay
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(e);
    } catch (e) {
      print("Signup failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  void _showErrorMessage(FirebaseAuthException e) {
    String message = "Signup failed. Please try again.";
    if (e.code == 'email-already-in-use') {
      message = "The email is already in use.";
    } else if (e.code == 'weak-password') {
      message = "The password is too weak.";
    } else if (e.code == 'invalid-email') {
      message = "Invalid email format.";
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
