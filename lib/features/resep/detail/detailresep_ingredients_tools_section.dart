part of '../detailresep.dart';

class _IngredientsToolsSection extends StatelessWidget {
  final Map<String, dynamic> r;

  const _IngredientsToolsSection({required this.r});

  @override
  Widget build(BuildContext context) {
    final String ingredientsRaw = (r['ingredients'] ?? '').toString();
    final String toolsRaw = (r['tools'] ?? '').toString();

    List<String> splitComma(String v) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final ingredients = splitComma(ingredientsRaw);
    final tools = splitComma(toolsRaw);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IngredientCard(
            title: 'Bahan',
            items: ingredients.isNotEmpty ? ingredients : const ['-'],
          ),
          const SizedBox(height: 12),
          _IngredientCard(
            title: 'Alat',
            items: tools.isNotEmpty ? tools : const ['-'],
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _IngredientCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.brandGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
