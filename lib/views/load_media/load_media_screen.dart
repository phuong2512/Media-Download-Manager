import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:media_download_manager/controllers/media_controller.dart';
import 'package:provider/provider.dart';
import 'package:media_download_manager/models/media.dart';
import 'package:media_download_manager/views/load_media/audio_tab.dart';
import 'package:media_download_manager/views/load_media/video_tab.dart';
import 'package:media_download_manager/widgets/bottom_sheets/media_options_bottom_sheet.dart';
import 'package:media_download_manager/widgets/dialogs/delete_media_dialog.dart';
import 'package:media_download_manager/widgets/dialogs/rename_media_dialog.dart';

class LoadMediaScreen extends StatefulWidget {
  const LoadMediaScreen({super.key});

  @override
  State<LoadMediaScreen> createState() => _LoadMediaScreenState();
}

class _LoadMediaScreenState extends State<LoadMediaScreen> {
  int selectedTabIndex = 0;
  String searchMedia = '';
  bool isSortNewestFirst = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final ctrl = context.read<MediaController>();
      if (ctrl.libraryMediaList.isEmpty) {
        await ctrl.scanLibrary();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List get filteredMediaList =>
      context.watch<MediaController>().libraryMediaList.where((m) {
        final isType = selectedTabIndex == 0
            ? m.type == "Audio"
            : m.type == "Video";
        final name = m.path.split('/').last.split('.').first.toLowerCase();
        final query = searchMedia.toLowerCase();
        return isType && name.contains(query);
      }).toList();

  void _handleMediaOptions(Media media) async {
    final action = await showMediaOptionsBottomSheet(context: context);
    if (!mounted) return;
    if (action == 'delete') {
      final confirmed = await showDeleteMediaDialog(context, media);
      if (!mounted) return;
      if (confirmed == true) {
        await context.read<MediaController>().deleteByPath(media.path);
        setState(() {});
      }
    } else if (action == 'rename') {
      final newName = await showRenameMediaDialog(context, media);
      if (!mounted) return;
      if (newName != null && newName.isNotEmpty) {
        await context.read<MediaController>().rename(media, newName);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Color(0xFF215B9D)),
          ),
        ],
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0XFF90C5E0), fontSize: 15),
          ),
        ),
        leadingWidth: 75,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabSwitch("Audio", 0),
              _buildTabSwitch("Video", 1),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                style: const TextStyle(color: Color(0xFF718CA5)),
                cursorColor: const Color(0xFF718CA5),
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchMedia = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search in your library...',
                  hintStyle: const TextStyle(color: Color(0xFF718CA5)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF718CA5),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic, color: Color(0xFF718CA5)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2F3D4C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: selectedTabIndex == 0
                  ? AudioTab(
                      audioList: filteredMediaList,
                      onMediaOptionsPressed: _handleMediaOptions,
                    )
                  : VideoTab(
                      videoList: filteredMediaList,
                      onMediaOptionsPressed: _handleMediaOptions,
                    ),
            ),
            const SizedBox(height: 10),
            IconButton(
              onPressed: () => _showSortOptionsDialog(context),
              icon: const Icon(
                Icons.filter_list,
                color: Color(0xFF215B9D),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitch(String label, int index) {
    final bool isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F3D4C) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: isSelected
                ? const Color(0XFF90C5E0)
                : const Color(0xFF394753),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSortOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Newest to Oldest'),
                trailing: isSortNewestFirst == true
                    ? const Icon(Icons.check, color: Colors.cyan, size: 45)
                    : null,
                onTap: () {
                  isSortNewestFirst == false ? sortToggle() : null;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest to Newest'),
                trailing: isSortNewestFirst == false
                    ? const Icon(Icons.check, color: Colors.cyan, size: 45)
                    : null,
                onTap: () {
                  isSortNewestFirst == true ? sortToggle() : null;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void sortToggle() {
    context.read<MediaController>().sortToggleByLastModified();
    setState(() {
      isSortNewestFirst = context.read<MediaController>().isSortNewestFirst;
      log('$isSortNewestFirst');
    });
  }
}
