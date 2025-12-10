import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http; // Import thêm cái này để test mạng

// Đảm bảo import đúng file của bạn
import 'api_service.dart';
import 'MemoryDetailPage.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFF009688);
const Color kPrimaryDark = Color(0xFF00796B);
const Color kBackgroundColor = Color(0xFFF0F2F5);
const Color kSurfaceColor = Colors.white;
const double kBorderRadius = 24.0;

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  final MemoryService _memoryService = MemoryService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> _memories = [];
  bool _isLoading = true;
  String? _currentlyPlayingSignedUrl;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();

    // 1. GỌI HÀM TEST MẠNG NGAY KHI VÀO
    _testNetworkConnection();

    // 2. Tải danh sách
    _fetchMemories();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed) {
            _currentlyPlayingSignedUrl = null;
          }
        });
      }
    });
  }

  // --- HÀM TEST MẠNG (DEBUG) ---
  Future<void> _testNetworkConnection() async {
    debugPrint("🔵 [NETWORK TEST] Đang kiểm tra kết nối Internet...");
    try {
      // Test Google
      final googleRes = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      debugPrint("✅ [NETWORK TEST] Kết nối Google OK (Status: ${googleRes.statusCode}) -> Máy ảo CÓ mạng.");
    } catch (e) {
      debugPrint("❌ [NETWORK TEST] Không thể kết nối Google -> Máy ảo MẤT mạng Internet!");
      debugPrint("👉 Lỗi chi tiết: $e");
      debugPrint("👉 Gợi ý: Tắt máy ảo, chọn 'Cold Boot Now' trong Device Manager.");
      return; // Mất mạng thì không test tiếp worker làm gì
    }

    try {
      // Test Worker
      debugPrint("🔵 [NETWORK TEST] Đang thử gọi Worker...");
      final workerRes = await http.get(Uri.parse('https://my-r2-worker.sangtd.workers.dev/generate-download-url?fileName=test_connection')).timeout(const Duration(seconds: 5));
      debugPrint("✅ [NETWORK TEST] Kết nối Worker OK (Status: ${workerRes.statusCode})");
    } catch (e) {
      debugPrint("❌ [NETWORK TEST] Không thể kết nối Worker!");
      debugPrint("👉 Lỗi chi tiết: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchMemories() async {
    debugPrint("🔵 [DATA] Bắt đầu tải danh sách Memories...");
    setState(() => _isLoading = true);
    try {
      final data = await _memoryService.getMemories(limit: 20);
      debugPrint("✅ [DATA] Tải thành công ${data.length} mục.");
      if (mounted) {
        setState(() {
          _memories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ [DATA] Lỗi tải danh sách: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Không thể tải ký ức: $e', isError: true);
      }
    }
  }

  Future<void> _handlePlayAudio(String signedUrl) async {
    try {
      if (_currentlyPlayingSignedUrl == signedUrl && _playerState == PlayerState.playing) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingSignedUrl = null);
      } else {
        await _audioPlayer.stop();
        debugPrint("🔊 Đang phát audio: $signedUrl");
        await _audioPlayer.play(UrlSource(signedUrl));
        setState(() => _currentlyPlayingSignedUrl = signedUrl);
      }
    } catch (e) {
      debugPrint("❌ Lỗi phát audio: $e");
      _showSnackBar('Lỗi phát âm thanh', isError: true);
    }
  }

  Future<void> _deleteMemory(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa ký ức?", style: TextStyle(color: Colors.red)),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _memoryService.deleteMemory(id);
        _showSnackBar("Đã xóa!");
        _fetchMemories();
      } catch (e) {
        _showSnackBar("Lỗi xóa: $e", isError: true);
      }
    }
  }

  void _openEditSheet(Map<String, dynamic> item) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMemorySheet(memoryService: _memoryService, item: item),
    );
    if (result == true) _fetchMemories();
  }

  void _openAddSheet() async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMemorySheet(memoryService: _memoryService),
    );
    if (result == true) _fetchMemories();
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    _audioPlayer.stop();
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        MemoryDetailPage(memoryId: item['id'], memoryService: _memoryService, initialData: item)
    ));
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Góc Ký Ức", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [kPrimaryColor, kPrimaryDark]))),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchMemories)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet, backgroundColor: kPrimaryDark,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Thêm", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchMemories,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
          itemCount: _memories.length,
          itemBuilder: (context, index) {
            return MemoryItemCard(
              item: _memories[index],
              memoryService: _memoryService,
              currentPlayingUrl: _currentlyPlayingSignedUrl,
              onPlayAudio: _handlePlayAudio,
              onDelete: () => _deleteMemory(_memories[index]['id']),
              onEdit: () => _openEditSheet(_memories[index]),
              onTap: () => _navigateToDetail(_memories[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(child: Text("Chưa có ký ức nào", style: TextStyle(color: Colors.grey[600])));
}

// =============================================================================
// WIDGET ITEM SIÊU DEBUG (Thay thế class MemoryItemCard cũ)
// =============================================================================
class MemoryItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final MemoryService memoryService;
  final String? currentPlayingUrl;
  final Function(String) onPlayAudio;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const MemoryItemCard({
    super.key,
    required this.item,
    required this.memoryService,
    required this.currentPlayingUrl,
    required this.onPlayAudio,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  State<MemoryItemCard> createState() => _MemoryItemCardState();
}

class _MemoryItemCardState extends State<MemoryItemCard> {
  Future<String?>? _linkFuture;
  Future<String?>? _audioFuture;

  // Biến để lưu ảnh dạng Byte nếu tải thành công
  Uint8List? _imageBytes;
  bool _isImageLoading = true;
  String _imageError = "";

  @override
  void initState() {
    super.initState();
    _audioFuture = widget.memoryService.getSignedUrl(widget.item['audio_url']);

    // Tự động tải và phân tích ảnh
    _loadImage();
  }

  // --- HÀM DEBUG QUAN TRỌNG: Tải và "Soi" dữ liệu trả về ---
  Future<void> _loadImage() async {
    final rawUrl = widget.item['image_url'];
    if (rawUrl == null) {
      if (mounted) setState(() => _isImageLoading = false);
      return;
    }

    try {
      // 1. Lấy Link Base64 từ API Service
      final signedUrl = await widget.memoryService.getSignedUrl(rawUrl);
      if (signedUrl == null) throw Exception("Không tạo được link signed");

      // 2. Tự gọi HTTP GET để xem Server trả về cái gì
      debugPrint("🔍 Đang tải ảnh từ: $signedUrl");
      final response = await http.get(Uri.parse(signedUrl), headers: {
        // Thêm Header giả lập Trình duyệt để tránh bị chặn
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
      });

      debugPrint("📥 Server trả về Status: ${response.statusCode}");
      debugPrint("📄 Content-Type: ${response.headers['content-type']}");

      // 3. Kiểm tra xem có phải ảnh không?
      final contentType = response.headers['content-type'] ?? "";

      if (response.statusCode == 200) {
        if (contentType.contains("image")) {
          // ✅ LÀ ẢNH -> HIỂN THỊ
          if (mounted) {
            setState(() {
              _imageBytes = response.bodyBytes;
              _isImageLoading = false;
            });
          }
        } else {
          // ❌ LÀ VĂN BẢN/HTML (Lỗi trá hình) -> IN RA LOG ĐỂ ĐỌC
          String bodyText = response.body;
          if (bodyText.length > 500) bodyText = bodyText.substring(0, 500) + "..."; // Cắt ngắn nếu dài quá

          debugPrint("🔴 LỖI: Server trả về Status 200 nhưng không phải ảnh!");
          debugPrint("👉 Nội dung server trả về: $bodyText");

          if (mounted) {
            setState(() {
              _imageError = "Server trả về text: $bodyText";
              _isImageLoading = false;
            });
          }
        }
      } else {
        // Lỗi HTTP khác
        if (mounted) {
          setState(() {
            _imageError = "Lỗi HTTP ${response.statusCode}";
            _isImageLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Lỗi ngoại lệ khi tải ảnh: $e");
      if (mounted) {
        setState(() {
          _imageError = e.toString();
          _isImageLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final content = item['content'] ?? "";
    String dateStr = "Unknown";
    try {
      final dt = DateTime.parse(item['created_at']).toLocal();
      dateStr = "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {}

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
              child: Row(
                children: [
                  const CircleAvatar(radius: 18, backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.favorite, size: 18, color: kPrimaryColor)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? widget.onEdit() : widget.onDelete(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                    ],
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_horiz, color: Colors.grey)),
                  )
                ],
              ),
            ),

            // --- KHUNG HIỂN THỊ ẢNH (LOGIC MỚI) ---
            if (item['image_url'] != null)
              Container(
                height: 250, width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isImageLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover) // Hiển thị ảnh từ RAM
                      : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text("Lỗi tải ảnh", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold)),
                          // Hiển thị lỗi nhỏ để biết nguyên nhân
                          Text(
                            _imageError.length > 50 ? "${_imageError.substring(0, 50)}..." : _imageError,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.4)),
              ),

            if (item['audio_url'] != null)
              FutureBuilder<String?>(
                future: _audioFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: InkWell(
                      onTap: () => widget.onPlayAudio(snapshot.data!),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: widget.currentPlayingUrl == snapshot.data ? kPrimaryColor : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.currentPlayingUrl == snapshot.data ? Icons.pause : Icons.play_arrow_rounded, color: kPrimaryColor),
                            const SizedBox(width: 8),
                            Text("Nghe ghi âm", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ADD MEMORY SHEET (GIỮ NGUYÊN)
// =============================================================================
class AddMemorySheet extends StatefulWidget {
  final MemoryService memoryService;
  const AddMemorySheet({super.key, required this.memoryService});
  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}
class _AddMemorySheetState extends State<AddMemorySheet> {
  final TextEditingController _contentController = TextEditingController();
  File? _selectedImage;
  File? _selectedAudio;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }
  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedAudio = File(result.files.single.path!));
    }
  }
  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cần chọn 1 bức ảnh!")));
      return;
    }
    setState(() => _isUploading = true);
    try {
      await widget.memoryService.createMemory(
        imageFile: _selectedImage!,
        audioFile: _selectedAudio,
        content: _contentController.text,
        tags: ["family"],
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Thêm Kỷ Niệm Mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryDark)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Chụp ảnh'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Chọn ảnh'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                      ]));
                    },
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100], borderRadius: BorderRadius.circular(20),
                        image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                      ),
                      child: _selectedImage == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: _contentController, maxLines: 3, decoration: const InputDecoration(hintText: "Nhập nội dung...", border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  ListTile(
                    tileColor: Colors.blue[50], leading: const Icon(Icons.mic, color: Colors.blue),
                    title: Text(_selectedAudio == null ? "Thêm giọng nói" : "Đã chọn tệp"),
                    trailing: _selectedAudio != null ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.add),
                    onTap: _pickAudio,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("LƯU", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EDIT MEMORY SHEET (GIỮ NGUYÊN)
// =============================================================================
class EditMemorySheet extends StatefulWidget {
  final MemoryService memoryService;
  final Map<String, dynamic> item;
  const EditMemorySheet({super.key, required this.memoryService, required this.item});
  @override
  State<EditMemorySheet> createState() => _EditMemorySheetState();
}
class _EditMemorySheetState extends State<EditMemorySheet> {
  final TextEditingController _contentController = TextEditingController();
  bool _isUpdating = false;
  @override
  void initState() {
    super.initState();
    _contentController.text = widget.item['content'] ?? "";
  }
  Future<void> _submitUpdate() async {
    setState(() => _isUpdating = true);
    try {
      await widget.memoryService.updateMemory(id: widget.item['id'], content: _contentController.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sửa Nội Dung", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _contentController, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: _isUpdating ? const CircularProgressIndicator(color: Colors.white) : const Text("CẬP NHẬT", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}


