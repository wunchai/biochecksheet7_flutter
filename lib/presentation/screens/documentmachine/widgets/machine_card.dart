import 'package:flutter/material.dart';
import 'package:biochecksheet7_flutter/data/database/app_database.dart';

class MachineCard extends StatelessWidget {
  final DbDocumentMachine machine;
  final VoidCallback onTap;

  const MachineCard({
    super.key,
    required this.machine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color/text based on aggregateStatus
    Color statusColor = Colors.grey;
    String statusText = 'Pending';
    IconData statusIcon = Icons.pending_outlined;

    // aggregateStatus: 0=Pending, 1=In Progress, 2=All Saved, 3=All Posted, 4=Fully Synced
    switch (machine.aggregateStatus) {
      case 1:
        statusColor = Colors.blue;
        statusText = 'In Progress';
        statusIcon = Icons.hourglass_top;
        break;
      case 2:
        statusColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.check_circle_outline;
        break;
      case 3:
        statusColor = Colors.orange;
        statusText = 'Posted';
        statusIcon = Icons.cloud_upload_outlined;
        break;
      case 4:
        statusColor = Colors.purple;
        statusText = 'Synced';
        statusIcon = Icons.cloud_done;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Pending';
        statusIcon = Icons.pending_outlined;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Machine Name and Main Status Icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.precision_manufacturing,
                        color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.machineName ?? 'Unknown Machine',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          machine.machineType ?? 'Type: N/A',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Semantic Status Badge (Right side)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Detailed Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      context, 'Total', '${machine.totalTags}', Colors.black87),
                  _buildStatItem(
                      context, 'Saved', '${machine.savedTags}', Colors.green),
                  _buildStatItem(context, 'Posted', '${machine.postedTags}',
                      Colors.orange),
                  _buildStatItem(context, 'Synced', '${machine.syncedTags}',
                      Colors.purple),
                ],
              ),
              if (machine.description != null &&
                  machine.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  machine.description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
