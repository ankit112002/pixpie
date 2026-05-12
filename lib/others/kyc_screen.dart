import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pixpie/dashboard/admin_dashboard/dashboard.dart';
import 'package:provider/provider.dart';

import '../provider/api_provider.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  int currentStep = 0;

  final fullName = TextEditingController();
  final dob = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pin = TextEditingController();

  final documentNumber = TextEditingController();
  final accountNumber = TextEditingController();
  final ifsc = TextEditingController();

  String documentType = "AADHAAR";
  String bankName = "";

  File? frontImage;
  File? backImage;
  File? selfieImage;
  File? bankProofImage;

  String? frontUrl;
  String? backUrl;
  String? selfieUrl;
  String? bankProofUrl;

  final aadhaarMask = MaskTextInputFormatter(
    mask: '#### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // ================= IMAGE PICK =================

  Future<File?> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked == null) return null;

    return File(picked.path);
  }

  // ================= COMPRESS =================

  Future<File> compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      "${file.path}_compressed.jpg",
      quality: 50,
      minWidth: 800,
      minHeight: 800,
    );

    return File(result!.path);
  }

  // ================= UPLOAD =================

  Future<String?> uploadImage(File file, String type) async {
    final api = context.read<ApiProvider>();

    await api.uploadKycDocument(
      filePath: file.path,
      type: type,
    );

    if (api.error != null) {
      _showMessage(api.error!);
      return null;
    }

    if (api.uploadedKycUrls.isNotEmpty) {
      return api.uploadedKycUrls.last;
    }

    return null;
  }

  // ================= BANK =================

  Future<String?> fetchBankName(String code) async {
    final url = Uri.parse(
      "https://ifsc.razorpay.com/$code",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["BANK"];
    }

    return null;
  }

  // ================= SNACKBAR =================

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ================= COMMON TEXTFIELD =================

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onTap: onTap,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ),
    );
  }

  // ================= IMAGE CARD =================

  Widget uploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 135,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          color: const Color(0xFFF8FAFC),
        ),
        child: image == null
            ? Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF7C3AED,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF7C3AED),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Stack(
          children: [
            ClipRRect(
              borderRadius:
              BorderRadius.circular(22),
              child: Image.file(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUBMIT =================

  // lib/others/kyc_screen.dart

  Future<void> submitKyc() async {
    final api = context.read<ApiProvider>();

    bool success = await api.submitKyc(
      fullName: fullName.text,
      dateOfBirth: dob.text,
      address: address.text,
      city: city.text,
      state: state.text,
      pinCode: pin.text,
      documentType: documentType,
      documentNumber: documentNumber.text.replaceAll(" ", ""),
      documentFrontUrl: frontUrl ?? "",
      documentBackUrl: backUrl ?? "",
      selfieUrl: selfieUrl ?? "",
      bankAccountNumber: accountNumber.text,
      ifscCode: ifsc.text,
      bankProofUrl: bankProofUrl ?? "",
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
            (route) => false,
      );
    } else {
      // ✅ CHANGE: Show the actual error from the API instead of a hardcoded string
      _showMessage(api.error ?? "KYC Submission Failed");
    }
  }

  // ================= COMMON IMAGE FLOW =================

  Future<void> handleImageUpload({
    required Function(File) setImage,
    required Function(String) setUrl,
    required String type,
  }) async {
    final file = await pickImage();

    if (file == null) return;

    final compressed = await compressImage(file);

    setState(() => setImage(compressed));

    final url = await uploadImage(
      compressed,
      type,
    );

    if (url != null) {
      setUrl(url);
    }
  }

  // ================= STEP HEADER =================

  Widget stepHeader(
      String title,
      String subtitle,
      ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            /// TOP BACKGROUND
            Container(
              height: size.height * 0.33,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF5B21B6),
                    Color(0xFF4C1D95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
              ),
            ),

            /// DECORATION
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            Positioned(
              top: 80,
              left: -20,
              child: Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            /// MAIN CONTENT
            SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 35),

                  /// ICON
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 48,
                      color: Color(0xFF7C3AED),
                    ),
                  ),

                  const SizedBox(height: 22),

                  stepHeader(
                    currentStep == 0
                        ? "Personal Details"
                        : currentStep == 1
                        ? "Document Verification"
                        : "Bank Verification",
                    currentStep == 0
                        ? "Fill your personal information"
                        : currentStep == 1
                        ? "Upload your documents securely"
                        : "Verify your bank details",
                  ),

                  const SizedBox(height: 28),

                  /// STEP INDICATOR
                  Row(
                    children: List.generate(
                      3,
                          (index) => Expanded(
                        child: Container(
                          margin:
                          const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(20),
                            color: currentStep >= index
                                ? const Color(0xFF7C3AED)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        /// STEP 1
                        if (currentStep == 0) ...[
                          buildField(
                            controller: fullName,
                            hint: "Full Name",
                            icon:
                            Icons.person_outline_rounded,
                          ),

                          buildField(
                            controller: dob,
                            hint: "Date of Birth",
                            icon:
                            Icons.calendar_month_rounded,
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate =
                              await showDatePicker(
                                context: context,
                                initialDate:
                                DateTime(2000),
                                firstDate:
                                DateTime(1900),
                                lastDate:
                                DateTime.now(),
                              );

                              if (pickedDate != null) {
                                dob.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                              }
                            },
                          ),

                          buildField(
                            controller: address,
                            hint: "Address",
                            icon: Icons.home_rounded,
                          ),

                          buildField(
                            controller: city,
                            hint: "City",
                            icon:
                            Icons.location_city_rounded,
                          ),

                          buildField(
                            controller: state,
                            hint: "State",
                            icon:
                            Icons.map_outlined,
                          ),

                          buildField(
                            controller: pin,
                            hint: "Pin Code",
                            icon:
                            Icons.pin_drop_rounded,
                            keyboardType:
                            TextInputType.number,
                          ),
                        ],

                        /// STEP 2
                        if (currentStep == 1) ...[
                          Container(
                            margin:
                            const EdgeInsets.only(
                              bottom: 18,
                            ),
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFF8FAFC),
                              borderRadius:
                              BorderRadius.circular(
                                18,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFFE5E7EB,
                                ),
                              ),
                            ),
                            child:
                            DropdownButtonFormField(
                              value: documentType,
                              decoration:
                              const InputDecoration(
                                border:
                                InputBorder.none,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "AADHAAR",
                                  child: Text(
                                    "AADHAAR",
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "PAN",
                                  child: Text("PAN"),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  documentType = v!;
                                });
                              },
                            ),
                          ),

                          buildField(
                            controller:
                            documentNumber,
                            hint: "Document Number",
                            icon:
                            Icons.badge_rounded,
                            keyboardType:
                            TextInputType.number,
                            inputFormatters: [
                              aadhaarMask,
                            ],
                          ),

                          uploadCard(
                            title:
                            "Upload Front Side",
                            image: frontImage,
                            onTap: () {
                              handleImageUpload(
                                setImage: (f) =>
                                frontImage = f,
                                setUrl: (u) =>
                                frontUrl = u,
                                type: "front",
                              );
                            },
                          ),

                          uploadCard(
                            title:
                            "Upload Back Side",
                            image: backImage,
                            onTap: () {
                              handleImageUpload(
                                setImage: (f) =>
                                backImage = f,
                                setUrl: (u) =>
                                backUrl = u,
                                type: "back",
                              );
                            },
                          ),

                          uploadCard(
                            title: "Upload Selfie",
                            image: selfieImage,
                            onTap: () {
                              handleImageUpload(
                                setImage: (f) =>
                                selfieImage = f,
                                setUrl: (u) =>
                                selfieUrl = u,
                                type: "selfie",
                              );
                            },
                          ),
                        ],

                        /// STEP 3
                        if (currentStep == 2) ...[
                          buildField(
                            controller:
                            accountNumber,
                            hint: "Account Number",
                            icon:
                            Icons.account_balance,
                            keyboardType:
                            TextInputType.number,
                          ),

                          buildField(
                            controller: ifsc,
                            hint: "IFSC Code",
                            icon:
                            Icons.credit_card_rounded,
                            onChanged: (value) async {
                              if (value.length ==
                                  11) {
                                final bank =
                                await fetchBankName(
                                  value,
                                );

                                if (bank != null) {
                                  setState(() {
                                    bankName = bank;
                                  });
                                }
                              }
                            },
                          ),

                          if (bankName.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin:
                              const EdgeInsets.only(
                                bottom: 18,
                              ),
                              padding:
                              const EdgeInsets.all(
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withOpacity(0.08),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  16,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance,
                                    color: Color(
                                      0xFF7C3AED,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 10),
                                  Expanded(
                                    child: Text(
                                      bankName,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .w700,
                                        color: Color(
                                          0xFF7C3AED,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          uploadCard(
                            title:
                            "Upload Bank Proof",
                            image: bankProofImage,
                            onTap: () {
                              handleImageUpload(
                                setImage: (f) =>
                                bankProofImage =
                                    f,
                                setUrl: (u) =>
                                bankProofUrl = u,
                                type:
                                "bank_proof",
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 10),

                        /// BUTTONS
                        Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child:
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        currentStep--;
                                      });
                                    },
                                    style:
                                    OutlinedButton
                                        .styleFrom(
                                      side:
                                      const BorderSide(
                                        color: Color(
                                          0xFF7C3AED,
                                        ),
                                      ),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          18,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      "Back",
                                      style:
                                      TextStyle(
                                        color: Color(
                                          0xFF7C3AED,
                                        ),
                                        fontWeight:
                                        FontWeight
                                            .w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            if (currentStep > 0)
                              const SizedBox(width: 14),

                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child:
                                ElevatedButton(
                                  onPressed:
                                  api.isLoading
                                      ? null
                                      : () {
                                    if (currentStep <
                                        2) {
                                      setState(
                                            () {
                                          currentStep++;
                                        },
                                      );
                                    } else {
                                      submitKyc();
                                    }
                                  },
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    elevation: 0,
                                    backgroundColor:
                                    const Color(
                                      0xFF7C3AED,
                                    ),
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        18,
                                      ),
                                    ),
                                  ),
                                  child:
                                  api.isLoading
                                      ? const SizedBox(
                                    height:
                                    24,
                                    width:
                                    24,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth:
                                      2.5,
                                      color: Colors
                                          .white,
                                    ),
                                  )
                                      : Text(
                                    currentStep ==
                                        2
                                        ? "Submit KYC"
                                        : "Continue",
                                    style:
                                    const TextStyle(
                                      color: Colors
                                          .white,
                                      fontWeight:
                                      FontWeight.w700,
                                      fontSize:
                                      15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}