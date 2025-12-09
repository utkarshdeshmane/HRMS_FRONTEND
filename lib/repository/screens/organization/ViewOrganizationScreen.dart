import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViewOrganizationScreen extends StatelessWidget {
  final Map<String, dynamic> organization;

  const ViewOrganizationScreen({
    Key? key,
    required this.organization,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String orgName = organization["orgName"]?.toString() ?? "Unknown";
    final String orgLocation = organization["orgLocation"]?.toString() ?? "N/A";
    final String orgContact = organization["orgContact"]?.toString() ?? "N/A";
    final String orgEmail = organization["orgEmail"]?.toString() ?? "N/A";
    final String orgLink = organization["orgLink"]?.toString() ?? "N/A";
    final String status = organization["orgStatus"]?.toString() ?? "Inactive";
    final String orgId = organization["_id"]?.toString() ?? 
                        organization["id"]?.toString() ?? "N/A";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Organization Details',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.domain_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orgName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == "active"
                                      ? Colors.green[400]
                                      : Colors.red[400],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status.toLowerCase() == "active"
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Organization ID',
                      value: orgId,
                      isDark: isDark,
                      isCopyable: true,
                      context: context,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      icon: Icons.business_rounded,
                      label: 'Organization Name',
                      value: orgName,
                      isDark: isDark,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      icon: Icons.toggle_on_rounded,
                      label: 'Status',
                      value: status,
                      isDark: isDark,
                      statusColor: status.toLowerCase() == "active"
                          ? Colors.green[600]
                          : Colors.red[600],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact Information Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: orgLocation,
                      isDark: isDark,
                      isMultiline: true,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Contact Number',
                      value: orgContact,
                      isDark: isDark,
                      isCopyable: true,
                      context: context,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      icon: Icons.email_rounded,
                      label: 'Email Address',
                      value: orgEmail,
                      isDark: isDark,
                      isCopyable: true,
                      context: context,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(
                      icon: Icons.link_rounded,
                      label: 'Website',
                      value: orgLink,
                      isDark: isDark,
                      isCopyable: true,
                      context: context,
                      isUrl: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isMultiline = false,
    bool isCopyable = false,
    bool isUrl = false,
    BuildContext? context,
    Color? statusColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: statusColor ?? Colors.blue[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        color: statusColor ?? (isDark ? Colors.white : Colors.black87),
                        fontWeight: statusColor != null ? FontWeight.bold : FontWeight.w600,
                        height: isMultiline ? 1.5 : 1.2,
                        decoration: isUrl ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                  if (isCopyable && context != null)
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                Text('Copied: $label'),
                              ],
                            ),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
