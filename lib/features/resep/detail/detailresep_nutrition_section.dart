part of '../detailresep.dart';

class _NutritionInfoSection extends StatelessWidget {
  final Map<String, dynamic> r;

  const _NutritionInfoSection({required this.r});

  @override
  Widget build(BuildContext context) {
    final int calories = _tryParseInt(r['caloriesValue']) > 0
        ? _tryParseInt(r['caloriesValue'])
        : _extractFirstNumber(r['calories']);

    final List<String> labels = _extractLabels(r);

    final String category = _pickFirstNonEmpty([r['category'], r['subtitle']]);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NutritionItem(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            label: calories > 0 ? 'Kalori \n$calories' : '',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _NutritionItem(
            icon: Icons.favorite,
            iconColor: Colors.red,
            label: labels.isNotEmpty ? 'Mengandung \n${labels.first}' : '',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _NutritionItem(
            icon: Icons.restaurant,
            iconColor: Colors.brown,
            label: category.isNotEmpty ? 'Kategori \n$category' : '',
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _NutritionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
