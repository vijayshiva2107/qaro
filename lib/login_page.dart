import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/carmerchant1.dart';
import 'package:flutter_application_1/carmerchantProfile.dart';
import 'package:flutter_application_1/merchant_home_page.dart';
import 'package:flutter_application_1/welcome_page.dart';
import 'package:flutter_application_1/signup_page.dart';
import 'merchant_home_page.dart';
import 'package:flutter_application_1/merchant_home_page.dart';
import 'package:flutter_application_1/carmerchantProfile.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  String _selectedAccount = "User"; // Default to 'User'
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isButtonEnabled = false;
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

Future<void> _signIn() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data not found.")),
        );
        return;
      }

      String storedAccountType = userDoc['accountType'];

      if (storedAccountType != _selectedAccount) {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Access denied! This account is registered as $storedAccountType.",
            ),
          ),
        );
        return;
      }

      // ✅ IF USER
      if (storedAccountType == "User") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }

      // ✅ IF MERCHANT
      else {
        // 🔥 CHECK IF MERCHANT DETAILS ALREADY EXISTS
        DocumentSnapshot merchantDoc = await FirebaseFirestore.instance
            .collection('merchants')
            .doc(userCredential.user!.uid)
            .get();

        if (merchantDoc.exists) {
          // 👉 Merchant already completed profile
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MerchantHomePage()),
          );
        } else {
          // 👉 First time login → go to fill details page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Carmerchant1()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.message}")),
      );
    }
  }
}
  /// 🔹 **Forgot Password Function**
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email to reset password")),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(color: Colors.black),
            child: const Center(
              
              child: Text(
                "LOGIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  letterSpacing: 3,
                ),
              ),
            ),
          ),

          // Expanded White Background
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  onChanged: _validateForm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Field
                      const Text("E-MAIL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(hintText: "eg: abc@gmail.com"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          } else if (!RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$').hasMatch(value)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      const Text("PASSWORD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: "********",
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          } else if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Account Type Selection
                      const Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          'ACCOUNT TYPE',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      // Radio Buttons for Account Type
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text("User"),
                              value: "User",
                              groupValue: _selectedAccount,
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccount = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text("Merchant"),
                              value: "Merchant",
                              groupValue: _selectedAccount,
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccount = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 100),

                      // Submit Button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isButtonEnabled ? Colors.black : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isButtonEnabled ? _signIn : null,
                          child: const Text("SUBMIT"),
                        ),
                      ),

                      const SizedBox(height: 10),
                      // 🔹 **Forgot Password Button**
                      Center(
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text("Forgot Password?", style: TextStyle(color: Colors.black)),
                        ),
                      ),

                      const SizedBox(height: 200),

                      // Signup Redirect
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Don't Have an Account?", style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                                );
                              },
                              child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
