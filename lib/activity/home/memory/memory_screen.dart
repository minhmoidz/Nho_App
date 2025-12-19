import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'MemoryDetailPage.dart';
import 'api_service.dart'; // Đảm bảo bạn có file này hoặc xóa dòng này đi nếu chưa cần
import 'package:nhoapp/constants/app_colors.dart';
import 'package:nhoapp/widgets/app_bar.dart';


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
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    _fetchMemories();

    // Khi hết bài thì reset icon
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingUrl = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchMemories() async {
    setState(() => _isLoading = true);
    try {
      final data = await _memoryService.getMemories();
      if (mounted) setState(() { _memories = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi tải data: $e");
    }
  }

  Future<void> _handlePlayAudio(String rawUrl) async {
    try {
      final signedUrl = await _memoryService.getSignedUrl(rawUrl);
      if (signedUrl == null) return;

      if (_currentlyPlayingUrl == signedUrl) {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingUrl = null);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(signedUrl));
        setState(() => _currentlyPlayingUrl = signedUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không thể phát âm thanh")));
    }
  }

  Future<void> _deleteMemory(int id) async {
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Xác nhận xóa"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
          ],
        )
    ) ?? false;

    if (confirm) {
      await _memoryService.deleteMemory(id);
      _fetchMemories();
    }
  }

  void _openAddSheet() async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => AddMemorySheet(memoryService: _memoryService),
    );
    if (result == true) _fetchMemories();
  }

  void _openEditSheet(Map<String, dynamic> item) async {
    final result = await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => EditMemorySheet(memoryService: _memoryService, item: item),
    );
    if (result == true) _fetchMemories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: NhoAppBar(
        title: "Ký ức của tôi",
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchMemories
          )
          ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
          ? const Center(child: Text("Chưa có ký ức nào", style: TextStyle(fontSize: 24),))
          : RefreshIndicator(
        onRefresh: _fetchMemories,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _memories.length,
          itemBuilder: (ctx, i) => MemoryItemCard(
            item: _memories[i],
            memoryService: _memoryService,
            currentlyPlayingUrl: _currentlyPlayingUrl,
            onPlayAudio: _handlePlayAudio,
            onDelete: () => _deleteMemory(_memories[i]['id']),
            onEdit: () => _openEditSheet(_memories[i]),
            onTap: () {
              // Navigate to detail if needed
              Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryDetailPage(memoryId: _memories[i]['id'], memoryService: _memoryService, initialData: _memories[i])));
            },
          ),
        ),
      ),
    );
  }
}

// --- WIDGET CARD ---
class MemoryItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final MemoryService memoryService;
  final String? currentlyPlayingUrl;
  final Function(String) onPlayAudio;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const MemoryItemCard({
    super.key, required this.item, required this.memoryService,
    required this.currentlyPlayingUrl, required this.onPlayAudio,
    required this.onDelete, required this.onEdit, required this.onTap
  });

  @override
  State<MemoryItemCard> createState() => _MemoryItemCardState();
}

class _MemoryItemCardState extends State<MemoryItemCard> {
  Uint8List? _imageBytes;
  bool _loadingImage = true;
  String? _signedAudioUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadAudioUrl();
  }

  void _loadAudioUrl() async {
    if (widget.item['audio_url'] != null) {
      final url = await widget.memoryService.getSignedUrl(widget.item['audio_url']);
      if (mounted) setState(() => _signedAudioUrl = url);
    }
  }

  void _loadImage() async {
    if (widget.item['image_url'] == null) return;
    try {
      final url = await widget.memoryService.getSignedUrl(widget.item['image_url']);
      if (url != null) {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200 && mounted) {
          setState(() { _imageBytes = res.bodyBytes; _loadingImage = false; });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isPlaying = _signedAudioUrl != null && _signedAudioUrl == widget.currentlyPlayingUrl;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
              title: Text("Kỷ niệm ngày: ${item['created_at'].toString().substring(0, 10)}"),
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text("Sửa")),
                  const PopupMenuItem(value: 'del', child: Text("Xóa", style: TextStyle(color: Colors.red))),
                ],
                onSelected: (v) => v == 'edit' ? widget.onEdit() : widget.onDelete(),
              ),
            ),

            // Image
            if (item['image_url'] != null)
              Container(
                height: 250, width: double.infinity,
                color: Colors.grey[200],
                child: _loadingImage
                    ? const Center(child: CircularProgressIndicator())
                    : _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),

            // Content
            if (item['content'] != null && item['content'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(item['content'], style: const TextStyle(fontSize: 16)),
              ),

            // Audio Player
            if (item['audio_url'] != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.teal.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: isPlaying ? Colors.teal : Colors.transparent),
                ),
                child: InkWell(
                  onTap: () => widget.onPlayAudio(item['audio_url']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: isPlaying ? Colors.teal : Colors.grey[400],
                        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(isPlaying ? "Đang phát..." : "Nghe ghi âm",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isPlaying ? Colors.teal : Colors.black87)),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// --- SHEET ADD MEMORY ---
class AddMemorySheet extends StatefulWidget {
  final MemoryService memoryService;
  const AddMemorySheet({super.key, required this.memoryService});
  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final _contentController = TextEditingController();
  File? _image;
  File? _audio;
  bool _uploading = false;

  Future<void> _pickImage(ImageSource src) async {
    final file = await ImagePicker().pickImage(source: src, imageQuality: 80);
    if (file != null) setState(() => _image = File(file.path));
  }

  Future<void> _pickAudio() async {
    // Dùng FilePicker để lấy audio chuẩn
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _audio = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa chọn ảnh!")));
      return;
    }
    setState(() => _uploading = true);
    try {
      await widget.memoryService.createMemory(
        imageFile: _image!,
        audioFile: _audio,
        content: _contentController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Thêm Ký Ức", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => showModalBottomSheet(context: context, builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(title: const Text("Chụp ảnh"), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                      ListTile(title: const Text("Thư viện"), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                    ])),
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                      child: _image != null
                          ? Image.file(_image!, fit: BoxFit.cover)
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40), Text("Chọn ảnh")]),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: _contentController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Nội dung...")),
                  const SizedBox(height: 15),
                  ListTile(
                    tileColor: Colors.blue[50],
                    leading: const Icon(Icons.mic, color: Colors.blue),
                    title: Text(_audio == null ? "Chọn Audio (MP3/M4A)" : "Audio đã chọn"),
                    subtitle: _audio != null ? Text(_audio!.path.split('/').last) : null,
                    trailing: _audio != null
                        ? IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _audio = null))
                        : const Icon(Icons.add),
                    onTap: _pickAudio,
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _uploading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: _uploading ? const CircularProgressIndicator(color: Colors.white) : const Text("ĐĂNG", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}

// --- SHEET EDIT ---
class EditMemorySheet extends StatefulWidget {
  final MemoryService memoryService;
  final Map<String, dynamic> item;
  const EditMemorySheet({super.key, required this.memoryService, required this.item});
  @override
  State<EditMemorySheet> createState() => _EditMemorySheetState();
}

class _EditMemorySheetState extends State<EditMemorySheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _controller.text = widget.item['content'] ?? "";
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Sửa nội dung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          TextField(controller: _controller, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity, height: 45,
            child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await widget.memoryService.updateMemory(id: widget.item['id'], content: _controller.text);
                  if(mounted) Navigator.pop(context, true);
                } catch(e) {
                  setState(() => _loading = false);
                }
              },
              child: _loading ? const CircularProgressIndicator() : const Text("Cập nhật"),
            ),
          )
        ],
      ),
    );
  }
}