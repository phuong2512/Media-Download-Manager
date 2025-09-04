import 'package:flutter/material.dart';
import 'package:media_download_manager/controllers/media_controller.dart';
import 'package:provider/provider.dart';
import 'package:media_download_manager/models/media.dart';
import 'package:media_download_manager/views/load_media/load_media_screen.dart';
import 'package:media_download_manager/utils/format.dart';
import 'package:media_download_manager/widgets/bottom_sheets/media_options_bottom_sheet.dart';
import 'package:media_download_manager/widgets/dialogs/delete_media_dialog.dart';
import 'package:media_download_manager/widgets/dialogs/rename_media_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MediaController>();
    final audioList = controller.audioList;
    final videoList = controller.videoList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Loader'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Color(0xFF215B9D)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _homeMediaListTile("Audio", audioList),
                const SizedBox(height: 10),
                _homeMediaListTile("Video", videoList),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: _addMediaToHome,
        ),
      ),
    );
  }

  void _addMediaToHome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoadMediaScreen()),
    );

    if (result != null && result is Media) {
      if (!mounted) return;
      context.read<MediaController>().addToHome(result);
    }
  }

  void _handleMediaOptions(Media media) async {
    final action = await showMediaOptionsBottomSheet(context: context);
    if (!mounted) return;
    if (action == 'delete') {
      final confirmed = await showDeleteMediaDialog(context, media);
      if (!mounted) return;
      if (confirmed == true) {
        await context.read<MediaController>().deleteByPath(media.path);
      }
    } else if (action == 'rename') {
      final newName = await showRenameMediaDialog(context, media);
      if (!mounted) return;
      if (newName != null && newName.isNotEmpty) {
        await context.read<MediaController>().rename(media, newName);
      }
    }
  }

  Widget _homeMediaListTile(String mediaType, List mediaList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mediaType,
          style: const TextStyle(fontSize: 15, color: Colors.white60),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mediaList.length,
          itemBuilder: (context, index) {
            final media = mediaList[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              leading: media.type == "Audio"
                  ? const Icon(
                      Icons.play_circle_outline,
                      color: Color(0xFFD48403),
                    )
                  : const Icon(Icons.ondemand_video, color: Colors.red),
              title: Text(
                media.path.split('/').last.split('.').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "${formatBytes(media.size)} | ${media.duration} | ${media.path.split('.').last}",
              ),
              onLongPress: () => _handleMediaOptions(media),
              trailing: IconButton(
                onPressed: () => _handleMediaOptions(media),
                icon: const Icon(Icons.more_horiz),
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }
}
