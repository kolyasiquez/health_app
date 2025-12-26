import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Terms and Conditions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Last updated: May 2025\n\n"
                  "Please read these terms and conditions carefully before using Our Service.\n\n"
                  "1. Interpretation and Definitions\n"
                  "The words of which the initial letter is capitalized have meanings defined under the following conditions. "
                  "The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.\n\n"
                  "2. Acknowledgment\n"
                  "These are the Terms and Conditions governing the use of this Service and the agreement that operates between You and the Company. "
                  "These Terms and Conditions set out the rights and obligations of all users regarding the use of the Service.\n\n"
                  "3. User Accounts\n"
                  "When You create an account with Us, You must provide Us information that is accurate, complete, and current at all times. "
                  "Failure to do so constitutes a breach of the Terms, which may result in immediate termination of Your account on Our Service.\n\n"
                  "4. Medical Disclaimer\n"
                  "The Service offers health information and is designed for educational and organizational purposes only. "
                  "You should not rely on this information as a substitute for, nor does it replace, professional medical advice, diagnosis, or treatment.\n\n"
                  "5. Privacy Policy\n"
                  "Your access to and use of the Service is also conditioned on Your acceptance of and compliance with the Privacy Policy of the Company. "
                  "Our Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your personal information when You use the Application or the Website and tells You about Your privacy rights and how the law protects You.\n\n"
                  "6. Contact Us\n"
                  "If you have any questions about these Terms and Conditions, You can contact us:\n"
                  "- By email: support@healthapp.com",
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}