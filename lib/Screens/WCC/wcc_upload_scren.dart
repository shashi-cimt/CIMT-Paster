import 'dart:io';
import 'package:canimage/Repository/remarks_repository.dart';
import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../Hive_Database/post_recca_image_upload_db.dart';
import '../../Hive_Database/remarks_db.dart';
import '../../Model/recca_remarks_model.dart';
import '../../Repository/postRecca_balance_count_change_repository.dart';
import '../../Repository/post_recca_image_upload_repository.dart';
import '../../generated/l10n.dart';
import '../PostReccaPostPlan/post_recca_see_plans.dart';
import '../printSync/post_recca_print_sync_screen.dart';


final Color primaryColor = Color(0xFF0056A4); // Deep Blue
final Color primaryLightColor = Color(0xFF00AEEF); // Sky Blue
final Color accentColor = Color(0xFF5BBAD5); // Soft Cyan
final Color neutralDarkColor = Color(0xFF2D2D2D); // Charcoal Grey
final Color neutralLightColor = Color(0xFFF4F4F4); // Light Grey
final Color pureWhiteColor = Color(0xFFFFFFFF); // Pure White

class WCCUploadSeePlanScreen extends StatefulWidget {
  String? projectID;
  String? villageName;
  String? brand;
  String? width;
  String? height;
  String? printNo;
  String? printId;
  String? planCode;
  String? villageCode;
  String? tensil;
  final Function(String) changeLanguage;
  WCCUploadSeePlanScreen({super.key, required this.projectID, required this.villageName, required this.brand, required this.width, required this.height, required this.printNo, required this.printId, required this.villageCode, required this.planCode, required this.tensil, required this.changeLanguage});

  @override
  State<WCCUploadSeePlanScreen> createState() => _WCCUploadSeePlanScreenState();
}

class _WCCUploadSeePlanScreenState extends State<WCCUploadSeePlanScreen> {
  final ImagePicker _picker = ImagePicker();
  List<ImageData> images = List.generate(7, (index) => ImageData()); // Changed to support 7 images
  List<ReccaRemarksModel>? plans;
  List<Remarks> dataRemarks = [];
  bool loader = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    fetchRemarks();
  }

  void fetchRemarks() async {
    setState(() {
      loader = true;
    });

    try {
      final remarksData = await RemarksHiveRepository().loadRemarks(); // Load remarks from Hive

      if (remarksData.isNotEmpty) {
        dataRemarks = remarksData; // Assign loaded remarks data to your list
        print('Remarks loaded from Hive: $dataRemarks');
      } else {
        print('No remarks found in Hive.');
      }
    } catch (e) {
      print('Error loading remarks: $e');
      Fluttertoast.showToast(msg: "Failed to load remarks. Please try again.");
    } finally {
      setState(() {
        loader = false;
      });
    }
  }

  Future<String> _storeImageInInternalDocuments(String imagePath) async {
    // Get the application document directory (internal storage)
    Directory? appDocDir = await getExternalStorageDirectory();
    if (appDocDir == null) {
      throw 'Unable to access external storage';
    }

    // Create the nested folder structure:
    Directory dwPaintingDir = Directory('${appDocDir.path}/CIMTDWP/PostRecca/Supervisor/${widget.projectID}/${widget.planCode}/${widget.villageCode}/${widget.printId}/Images');

    // Create the folder if it does not exist
    if (!await dwPaintingDir.exists()) {
      await dwPaintingDir.create(recursive: true);
    }

    // Read the image file into bytes
    File imageFile = File(imagePath);
    var imageBytes = await imageFile.readAsBytes();

    // Compress the image bytes to reduce size
    int targetWidth = 800;
    int targetHeight = 800;

    var result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: 90,
      format: CompressFormat.png,
    );

    // Check if the image is compressed
    if (result == null) {
      throw 'Image compression failed';
    }

    // Define the image name
    String imageName = 'Img_${DateTime.now().toIso8601String().replaceAll(RegExp('[^0-9]'), '')}.png';

    // Define the full path where the image will be stored
    String imagePathInStorage = '${dwPaintingDir.path}/$imageName';

    // Create a new file from the compressed result and save it
    File compressedImage = File(imagePathInStorage);
    await compressedImage.writeAsBytes(result);

    return imagePathInStorage;
  }

  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedRemarks = {};
  final TextEditingController _remarksDisplayCtrl = TextEditingController();

  @override
  void dispose() {
    _focusNode.dispose();
    _remarksDisplayCtrl.dispose();
    super.dispose();
  }

  void _openRemarksDialog() async {
    final temp = Set<String>.from(_selectedRemarks); // Store remarks as Strings, not ids

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(S.of(context).pleaseSelect, style: TextStyle(fontFamily: "Poppins", fontSize: 14)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: dataRemarks.map((opt) {
                      final checked = temp.contains(opt.remarks); // Check if remarks text is selected
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: checked,
                        dense: true,
                        title: Text(opt.remarks, style: TextStyle(fontFamily: "Poppins")),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              temp.add(opt.remarks); // Add the remark text instead of the id
                            } else {
                              temp.remove(opt.remarks); // Remove the remark text instead of the id
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(S.of(context).cancel, style: TextStyle(fontFamily: "Poppins")),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRemarks
                        ..clear()
                        ..addAll(temp); // Store selected remarks texts
                      _remarksDisplayCtrl.text = _selectedRemarks.join(', ');
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(S.of(context).submit, style: TextStyle(fontFamily: "Poppins")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SUSeePlanScreen(changeLanguage: widget.changeLanguage,)),
    );
    return false;
  }

  // New method for grid image preview
  void _previewImage(int index) {
    if (images[index].imagePath == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(images[index].imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 40,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                right: 40,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeGridImage(index);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // New method to remove grid image
  void _removeGridImage(int index) {
    setState(() {
      images[index].imagePath = null;
      images[index].lat = 0.0;
      images[index].long = 0.0;
    });
  }

  // New method for picking image for grid
  Future<void> _pickImageForGrid() async {
    // Find the first empty slot
    int emptyIndex = images.indexWhere((img) => img.imagePath == null);

    if (emptyIndex == -1) {
      Fluttertoast.showToast(msg: "Maximum 7 images allowed");
      return;
    }

    try {
      final ImageSource source = ImageSource.camera;
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        Position currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        setState(() {
          images[emptyIndex].imagePath = pickedFile.path;
          images[emptyIndex].lat = currentPosition.latitude;
          images[emptyIndex].long = currentPosition.longitude;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      Fluttertoast.showToast(msg: S.of(context).failedImage);
    }
  }

  // New method to build grid image card
  Widget _buildGridImageCard(int index) {
    final hasImage = images[index].imagePath != null;

    return GestureDetector(
      onTap: hasImage ? () => _previewImage(index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: hasImage
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(images[index].imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Delete button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeGridImage(index),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
            // Image number badge
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        )
            : Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 24,
                color: Colors.grey[400],
              ),
              SizedBox(height: 4),
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndSavePDF() async {
    try {
      // Filter uploaded images
      List<ImageData> uploadedImages = images.where((img) => img.imagePath != null).toList();

      if (uploadedImages.isEmpty) {
        Fluttertoast.showToast(msg: "No images to generate PDF");
        return;
      }

      final pdf = pw.Document();

      // Load images as pw.MemoryImage
      List<pw.MemoryImage> pdfImages = [];
      for (var img in uploadedImages) {
        final file = File(img.imagePath!);
        final bytes = await file.readAsBytes();
        pdfImages.add(pw.MemoryImage(bytes));
      }

      // Create PDF pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          header: (context) => _buildPDFHeader(),
          build: (context) => [
            _buildPDFContent(pdfImages, uploadedImages),
          ],
        ),
      );

      // Save PDF to device
      await _savePDFToDevice(pdf);

    } catch (e) {
      print('Error generating PDF: $e');
      Fluttertoast.showToast(msg: "Failed to generate PDF: $e");
    }
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      padding: pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CAN IMAGE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Digital Wall Construction Report',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Report ID: ${widget.printId}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFContent(List<pw.MemoryImage> pdfImages, List<ImageData> uploadedImages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Project Information Section
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Project Information',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildInfoRow('Village Name:', 'CBE'),
                  ),
                  pw.Expanded(
                    child: _buildInfoRow('Print No:', 'A01'),
                  ),
                ],
              ),


            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Images Section
        pw.Text(
          'Construction Images (${pdfImages.length} images)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),

        // Image Grid (2 images per row)
        ...List.generate(
          (pdfImages.length / 2).ceil(),
              (rowIndex) {
            final startIndex = rowIndex * 2;
            final endIndex = (startIndex + 2 > pdfImages.length)
                ? pdfImages.length
                : startIndex + 2;

            return pw.Container(
              margin: pw.EdgeInsets.only(bottom: 15),
              child: pw.Row(
                children: [
                  for (int i = startIndex; i < endIndex; i++) ...[
                    pw.Expanded(
                      child: pw.Container(
                        margin: pw.EdgeInsets.only(right: i == endIndex - 1 ? 0 : 10),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              height: 180,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300),
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 8,
                                verticalRadius: 8,
                                child: pw.Image(
                                  pdfImages[i],
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Container(
                              padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey100,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    'Image ${i + 1}',
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  // pw.Text(
                                  //   'Lat: ${uploadedImages[i].lat.toStringAsFixed(6)}',
                                  //   style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                                  // ),
                                  // pw.Text(
                                  //   'Lng: ${uploadedImages[i].long.toStringAsFixed(6)}',
                                  //   style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Add empty space if odd number of images
                  if (endIndex - startIndex == 1) pw.Expanded(child: pw.Container()),
                ],
              ),
            );
          },
        ),

        pw.SizedBox(height: 20),

        // Footer Information
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'This document was automatically generated by CAN IMAGE system',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Report contains ${pdfImages.length} construction images with GPS coordinates',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _savePDFToDevice(pw.Document pdf) async {
    try {
      // Get external storage directory
      Directory? appDocDir = await getExternalStorageDirectory();
      if (appDocDir == null) {
        throw 'Unable to access external storage';
      }

      // Create PDF folder structure
      Directory pdfDir = Directory('${appDocDir.path}/CIMTDWP/Reports/${widget.projectID}/${widget.planCode}/${widget.villageCode}');

      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      // Generate PDF filename
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String filename = 'CBE_A01_Report_$timestamp.pdf';
      String filePath = '${pdfDir.path}/$filename';

      // Save PDF file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show success message with file path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved successfully!\nPath: $filePath'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      print('PDF saved at: $filePath');

    } catch (e) {
      print('Error saving PDF: $e');
      Fluttertoast.showToast(msg: "Failed to save PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            title: Text(
              S.of(context).printDetails,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Poppins"
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage,)),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  // Info action
                },
              ),
            ],
          ),
          body: loader == true ? Center(child: CircularProgressIndicator(color: Colors.blue,)) : SingleChildScrollView(
            child: Column(
              children: [
                // Enhanced Header Card
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EnhancedMetaRow(label: S.of(context).villageNameMap, value: "CBE"),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                S.of(context).printNo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: neutralDarkColor,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ),
                            SizedBox(width: 55,),
                            Center(
                              child: Text(
                                "A01",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: neutralDarkColor,
                                  fontFamily: "Poppins",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Images Section - NEW GRID LAYOUT
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library, color: primaryColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              S.of(context).uploadImages,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: neutralDarkColor,
                                fontFamily: "Poppins",
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${images.where((img) => img.imagePath != null).length}/7',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grid layout for images
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          return _buildGridImageCard(index);
                        },
                      ),

                      SizedBox(height: 16),

                      // Add Photo Button (shown when less than 7 images are uploaded)
                      if (images.where((img) => img.imagePath != null).length < 7)
                        Center(
                          child: GestureDetector(
                            onTap: () => _pickImageForGrid(),
                            child: Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 20,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    S.of(context).addPhoto,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                      fontFamily: "Poppins",
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

                SizedBox(height: 20),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10, top: 10),
                        width: 150,
                        height: 50,
                        child: GestureDetector(
                          onTap: () async {
                            final uploadedCount = images.where((img) => img.imagePath != null).length;
                            if (uploadedCount < 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please upload at least 1 image to generate PDF"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await _generateAndSavePDF();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, size: 15, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Generate PDF",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.only(bottom: 10, top: 10),
                        width: 150,
                        height: 50,
                        child: GestureDetector(
                          onTap: isRefreshing ? null : _submitDetails,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isRefreshing ? Colors.grey : primaryColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isRefreshing) ...[
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ] else...[
                                  Icon(Icons.cloud_upload_outlined, size: 15, color: Colors.white,),
                                  SizedBox(width: 8),
                                ],
                                Text(
                                  isRefreshing ? "Saving..." : S.of(context).submitDetails,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: "Poppins",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitDetails() async {
    setState(() {
      isRefreshing = true;
    });

    final remarksIds = dataRemarks
        .where((remark) => _selectedRemarks.contains(remark.remarks))
        .map((remark) => remark.id)
        .toList();

    String remarksString = remarksIds.join(", ");

    if (_selectedRemarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).selectRemarks),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    // Check if at least 1 image is uploaded
    final uploadedCount = images.where((img) => img.imagePath != null).length;
    if (uploadedCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please upload at least 1 image"),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isRefreshing = false;
      });
      return;
    }

    // Compress images before submitting
    for (var i = 0; i < images.length; i++) {
      if (images[i].imagePath != null) {
        final compressedImagePath = await _storeImageInInternalDocuments(images[i].imagePath!);
        images[i].imagePath = compressedImagePath;
      }
    }

    String currentDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Create metadata with all uploaded images
    List<String> imagePaths = [];
    List<String> latitudes = [];
    List<String> longitudes = [];

    for (var img in images) {
      if (img.imagePath != null) {
        imagePaths.add(img.imagePath!);
        latitudes.add(img.lat.toString());
        longitudes.add(img.long.toString());
      }
    }

    // You'll need to modify your SUImageUploaddata model to handle multiple images
    // For now, keeping the original structure but you should update it
    SUImageUploaddata metadata = SUImageUploaddata(
        printId: widget.printId.toString(),
        planCode: widget.planCode.toString(),
        nearImagePath: imagePaths.isNotEmpty ? imagePaths[0] : null,
        nearLatitude: latitudes.isNotEmpty ? latitudes[0] : "0.0",
        nearLongitude: longitudes.isNotEmpty ? longitudes[0] : "0.0",
        farImagePath: imagePaths.length > 1 ? imagePaths[1] : null,
        farLatitude: latitudes.length > 1 ? latitudes[1] : "0.0",
        farLongitude: longitudes.length > 1 ? longitudes[1] : "0.0",
        villageCode: widget.villageCode.toString(),
        remark: remarksIds.join(", "),
        executionDate: currentDate,
        uploadDate: '',
        villageName: widget.villageName.toString(),
        tensil: widget.tensil.toString(),
        printNo: widget.printNo.toString(),  createdAt: DateTime.now(),  // ADD THIS LINE
    );

    await PostReccaImageUploadHiveRepository().saveSUImageMetadata(metadata);

    await CountChangeHiveRepository().incrementOfflineCount(
      widget.planCode.toString(),
      widget.villageCode.toString(),
      widget.villageName.toString(),
      widget.tensil.toString(),
    );

    // Show success message and navigate to the next screen
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(S.of(context).submitPlan),
      backgroundColor: Colors.green,
    ));
    setState(() {
      isRefreshing = false;
    });
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SUPrintSyncScreen(changeLanguage: widget.changeLanguage,)));
  }
}

class ImageData {
  String? imagePath;
  String printNumber;
  double lat;
  double long;
  TextEditingController printController;

  ImageData({
    this.imagePath,
    this.printNumber = '',
    this.lat = 0.0,
    this.long = 0.0,
  }) : printController = TextEditingController(text: printNumber);

  void dispose() {
    printController.dispose();
  }
}

// Enhanced Meta Row Components
class _EnhancedMetaRow extends StatelessWidget {
  const _EnhancedMetaRow({
    required this.label,
    required this.value
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedMetaRowWithInputs extends StatelessWidget {
  const _EnhancedMetaRowWithInputs({
    required this.label,
    required this.value,
    required this.secondValue
  });

  final String label;
  final String value;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
          SizedBox(width: 83),
          Center(
            child: Text(
              "${value}W",
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
          SizedBox(width: 4),
          Text('×', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          SizedBox(width: 4),
          Center(
            child: Text(
              "${secondValue}H",
              style: TextStyle(
                fontSize: 12,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedMetaRowWithInputs1 extends StatelessWidget {
  const _EnhancedMetaRowWithInputs1({
    required this.label,
    required this.value,
    required this.secondValue
  });

  final String label;
  final String value;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: neutralDarkColor,
                fontFamily: "Poppins",
              ),
            ),
          ),
          Container(
            width: 98,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: neutralDarkColor,
                  fontFamily: "Poppins",
                ),
              ),
            ),
          ),
          Container()
        ],
      ),
    );
  }
}