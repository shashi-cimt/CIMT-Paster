import 'package:canimage/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../utils/fonts.dart';
import '../../widgets/common_app_bar.dart';

class HelpSupportScreen extends StatefulWidget {
  final Function(String) changeLanguage;

  const HelpSupportScreen({super.key, required this.changeLanguage});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchYouTube(String url) async {
    final Uri youtubeUrl = Uri.parse(url);
    if (!await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(
        msg: 'Could not open YouTube video',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _submitEnquiry() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _whatsappController.text.trim();
      final message = _messageController.text.trim();

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'app.support1@canimagemediatech.com',
        queryParameters: {
          'cc': 'TL3@canimagemediatech.com',
          'subject': 'Support Enquiry - $name',
          'body':
              'Name: $name\n'
              'Email: $email\n'
              'WhatsApp: $phone\n\n'
              'Message:\n$message',
        },
      );

      try {
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // Continue to show dialog if mail app couldn't open
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                'Thank You!',
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Font.primaryColor,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your enquiry has been submitted successfully. We will get back to you shortly.',
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 13.5,
              color: Color(0xFF334155),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
                _nameController.clear();
                _emailController.clear();
                _whatsappController.clear();
                _messageController.clear();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentPage == 1) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CommonAppBar(
          title: S.of(context).helpSupport,
          actions: const [CommonHomeButton()],
        ),
        body: SafeArea(
          top: false,
          child: Column(
              children: [
                // Top Tab Segment Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _currentPage == 0
                                  ? Font.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _currentPage == 0
                                  ? [
                                      BoxShadow(
                                        color: Font.primaryColor.withOpacity(
                                          0.25,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 18,
                                  color: _currentPage == 0
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tutorial',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: _currentPage == 0
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _currentPage == 1
                                  ? Font.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _currentPage == 1
                                  ? [
                                      BoxShadow(
                                        color: Font.primaryColor.withOpacity(
                                          0.25,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.headset_mic_rounded,
                                  size: 18,
                                  color: _currentPage == 1
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: _currentPage == 1
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [_buildTutorialPage(), _buildEnquiryPage()],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildTutorialPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Text(
            'Welcome to Can Image!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Font.primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Learn how to use the app effectively',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 20),

          // Video Tutorial Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                _launchYouTube('https://www.youtube.com/watch?v=YOUR_VIDEO_ID');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Font.primaryColor,
                      Font.primaryColor.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 76,
                      color: Colors.white,
                    ),
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Watch Tutorial Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Features Section
          Text(
            'Key Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Font.primaryColor,
            ),
          ),
          const SizedBox(height: 14),

          _buildFeatureCard(
            icon: Icons.location_on_rounded,
            title: 'See Plans & Maps',
            description:
                'View all your assigned plans and navigate to locations easily with integrated maps.',
            color: Font.primaryColor,
          ),

          _buildFeatureCard(
            icon: Icons.camera_alt_rounded,
            title: 'Capture Images',
            description:
                'Take high-quality photos with GPS coordinates and timestamps for accurate documentation.',
            color: Font.primaryColor,
          ),

          _buildFeatureCard(
            icon: Icons.cloud_upload_rounded,
            title: 'Sync Data',
            description:
                'Upload your captured images and data seamlessly when connected to the internet.',
            color: Font.primaryColor,
          ),

          _buildFeatureCard(
            icon: Icons.dashboard_rounded,
            title: 'Track Progress',
            description:
                'Monitor your work progress and view detailed statistics on the dashboard.',
            color: Font.primaryColor,
          ),

          _buildFeatureCard(
            icon: Icons.print_rounded,
            title: 'Print Sync',
            description:
                'Synchronize print data and manage your printing workflow efficiently.',
            color: Font.primaryColor,
          ),

          const SizedBox(height: 20),

          // Tips Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Font.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Font.primaryColor.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Font.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Font.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Keep your GPS enabled for accurate location tracking',
                ),
                _buildTipItem('Sync your data regularly to avoid data loss'),
                _buildTipItem(
                  'Check pending sync count before starting new work',
                ),
                _buildTipItem('Use the dashboard to track your daily progress'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Support Card at bottom of tutorial
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Font.primaryColor,
                  Font.primaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Font.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Have Questions?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get in touch with our team directly',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(
                    Icons.send_rounded,
                    size: 15,
                    color: Font.primaryColor,
                  ),
                  label: Text(
                    'Contact Us',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Font.primaryColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Font.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Font.primaryColor.withOpacity(0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Font.primaryColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Font.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: Font.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      color: Font.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontFamily: 'Roboto',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: Font.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Roboto',
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Font.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill out the form below and we\'ll get back to you shortly',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                labelStyle: const TextStyle(fontFamily: 'Roboto'),
                prefixIcon: Icon(
                  Icons.person_rounded,
                  color: Font.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Font.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: const TextStyle(fontFamily: 'Roboto'),
                prefixIcon: Icon(Icons.email_rounded, color: Font.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Font.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // WhatsApp Field
            TextFormField(
              controller: _whatsappController,
              decoration: InputDecoration(
                labelText: 'WhatsApp Number *',
                labelStyle: const TextStyle(fontFamily: 'Roboto'),
                prefixIcon: Icon(Icons.phone_rounded, color: Font.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Font.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your WhatsApp number';
                }
                if (value.length < 10) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message *',
                labelStyle: const TextStyle(fontFamily: 'Roboto'),
                prefixIcon: Icon(
                  Icons.message_rounded,
                  color: Font.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Font.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontFamily: 'Roboto'),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your message';
                }
                if (value.length < 10) {
                  return 'Message should be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitEnquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Font.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Enquiry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Font.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Font.primaryColor.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: Font.primaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Other Ways to Reach Us',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          color: Font.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildContactActionItem(
                    icon: Icons.email_rounded,
                    title: 'Email Support',
                    subtitle: 'app.support1@canimagemediatech.com',
                    onTap: _launchEmailSupport,
                  ),
                  const SizedBox(height: 10),
                  _buildContactActionItem(
                    icon: Icons.phone_rounded,
                    title: 'Support Number',
                    subtitle: '+91 78430 94514',
                    onTap: _launchPhoneCall,
                  ),
                  const SizedBox(height: 10),
                  _buildContactActionItem(
                    icon: Icons.access_time_rounded,
                    title: 'Working Hours',
                    subtitle: 'Mon-Fri: 9:00 AM - 6:00 PM',
                    onTap: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmailSupport() async {
    final Uri emailUri = Uri.parse(
      'mailto:app.support1@canimagemediatech.com?cc=TL3@canimagemediatech.com&subject=Support%20Enquiry',
    );
    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await Clipboard.setData(
          const ClipboardData(text: 'app.support1@canimagemediatech.com'),
        );
        Fluttertoast.showToast(
          msg: "Email copied to clipboard: app.support1@canimagemediatech.com",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      await Clipboard.setData(
        const ClipboardData(text: 'app.support1@canimagemediatech.com'),
      );
      Fluttertoast.showToast(
        msg: "Email copied to clipboard: app.support1@canimagemediatech.com",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _launchPhoneCall() async {
    final Uri phoneUri = Uri.parse('tel:+917843094514');
    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await Clipboard.setData(const ClipboardData(text: '+917843094514'));
        Fluttertoast.showToast(
          msg: "Number copied to clipboard: +91 78430 94514",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: '+917843094514'));
      Fluttertoast.showToast(
        msg: "Number copied to clipboard: +91 78430 94514",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Widget _buildContactActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Font.primaryColor.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Font.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: Font.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                        color: onTap != null
                            ? Font.primaryColor
                            : const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Font.primaryColor.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
