import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medapp/screens/15_DataManagementInformationScreen.dart';
import 'package:medapp/screens/15_settings_screen.dart';

import '../07_SosScreen.dart';
import '../08_MedicalDocumentScreen.dart';
import '../09_DoctorUploadScreen.dart';
import '../10_CommunityMenu.dart';
import '../11_SendMessageCommunity.dart';
import '../12_ReceiveMessageCommunity.dart';
import '../13_ChatPartnerSelection.dart';

class Sidebar extends StatelessWidget {
  final int totalUnread;
  final VoidCallback loadUnreadCount;
  final VoidCallback logout;

  const Sidebar({
    Key? key,
    required this.totalUnread,
    required this.loadUnreadCount,
    required this.logout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Center(
              child: Text(
                'Menu',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('Home', style: GoogleFonts.lato()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('Profile', style: GoogleFonts.lato()),
            onTap: () {
              // Navigator.push(...)
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('Settings', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text('Document Upload', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorUploadScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: Text('Data Management Information', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DataManagementInformationScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.message_rounded),
            title: Text('Your Communitys', style: GoogleFonts.lato()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommunityFeedScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mark_chat_read_outlined),
            title: Row(
              children: [
                Text('Chat', style: GoogleFonts.lato()),
                if (totalUnread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalUnread',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) => const ChatPartnerSelectionScreen(),
                ),
              )
                  .then((_) => loadUnreadCount());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('Logout', style: GoogleFonts.lato()),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}
