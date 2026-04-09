import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
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
      imageQuality: 60, // 🔥 reduce size at source
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
      quality: 50, // 🔥 aggressive compression
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(api.error!)),
      );
      return null;
    }

    if (api.uploadedKycUrls.isNotEmpty) {
      return api.uploadedKycUrls.last;
    }

    return null;
  }

  // ================= BANK FETCH =================
  Future<String?> fetchBankName(String code) async {
    final url = Uri.parse("https://ifsc.razorpay.com/$code");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["BANK"];
    }

    return null;
  }

  // ================= UI CARD =================
  Widget uploadCard(String title, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: image == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 28),
            const SizedBox(height: 6),
            Text(title),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(image, fit: BoxFit.cover),
        ),
      ),
    );
  }

  // ================= SUBMIT =================
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
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("KYC Submission Failed")),
      );
    }
  }

  // ================= COMMON PICK + UPLOAD =================
  Future<void> handleImageUpload({
    required Function(File) setImage,
    required Function(String) setUrl,
    required String type,
  }) async {
    final file = await pickImage();
    if (file == null) return;

    final compressed = await compressImage(file);

    setState(() => setImage(compressed));

    final url = await uploadImage(compressed, type);

    if (url != null) {
      setUrl(url);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your KYC")),
      body: Stepper(
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep < 2) {
            setState(() => currentStep++);
          } else {
            submitKyc();
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() => currentStep--);
          }
        },
        steps: [
          /// STEP 1
          Step(
            title: const Text("Personal"),
            content: Column(
              children: [
                TextField(controller: fullName, decoration: const InputDecoration(labelText: "Full Name")),
                TextField(
                  controller: dob,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          dob.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                  ),
                ),
                TextField(controller: address, decoration: const InputDecoration(labelText: "Address")),
                TextField(controller: city, decoration: const InputDecoration(labelText: "City")),
                TextField(controller: state, decoration: const InputDecoration(labelText: "State")),
                TextField(controller: pin, decoration: const InputDecoration(labelText: "Pin Code")),
              ],
            ),
          ),

          /// STEP 2
          Step(
            title: const Text("Documents"),
            content: Column(
              children: [
                DropdownButtonFormField(
                  value: documentType,
                  items: const [
                    DropdownMenuItem(value: "AADHAAR", child: Text("AADHAAR")),
                    DropdownMenuItem(value: "PAN", child: Text("PAN")),
                  ],
                  onChanged: (v) => setState(() => documentType = v!),
                ),
                TextField(
                  controller: documentNumber,
                  inputFormatters: [aadhaarMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Document Number"),
                ),

                uploadCard("Upload Front", frontImage, () {
                  handleImageUpload(
                    setImage: (f) => frontImage = f,
                    setUrl: (u) => frontUrl = u,
                    type: "front",
                  );
                }),

                uploadCard("Upload Back", backImage, () {
                  handleImageUpload(
                    setImage: (f) => backImage = f,
                    setUrl: (u) => backUrl = u,
                    type: "back",
                  );
                }),

                uploadCard("Upload Selfie", selfieImage, () {
                  handleImageUpload(
                    setImage: (f) => selfieImage = f,
                    setUrl: (u) => selfieUrl = u,
                    type: "selfie",
                  );
                }),
              ],
            ),
          ),

          /// STEP 3
          Step(
            title: const Text("Bank"),
            content: Column(
              children: [
                TextField(controller: accountNumber, decoration: const InputDecoration(labelText: "Account Number")),
                TextField(
                  controller: ifsc,
                  decoration: const InputDecoration(labelText: "IFSC Code"),
                  onChanged: (value) async {
                    if (value.length == 11) {
                      final bank = await fetchBankName(value);
                      if (bank != null) setState(() => bankName = bank);
                    }
                  },
                ),
                if (bankName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text("Bank: $bankName", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),

                uploadCard("Upload Bank Proof", bankProofImage, () {
                  handleImageUpload(
                    setImage: (f) => bankProofImage = f,
                    setUrl: (u) => bankProofUrl = u,
                    type: "bank_proof",
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}