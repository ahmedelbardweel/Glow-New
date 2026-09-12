import 'package:flutter/material.dart';

void showAdminActionsBottomSheet({
  required BuildContext context,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'تعديل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                title: const Text(
                  'حذف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}
