import 'package:flutter/material.dart';

import '../../../../utils/app_theme.dart';

class SensorRow extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final TextEditingController controller;

  const SensorRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: selected,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
          ),
        ),
        if (selected)
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Qty',
              ),
            ),
          ),
      ],
    );
  }
}

