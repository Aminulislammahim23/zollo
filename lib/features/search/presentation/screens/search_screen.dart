import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/providers/products_provider.dart';
import '../providers/search_providers.dart';

/// `/search`, spec C19.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
  }

  Future<void> _submit(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    await ref.read(recentSearchesProvider.notifier).add(q);
    if (!mounted) return;
    context.push('/products?q=${Uri.encodeQueryComponent(q)}');
  }

  void _fill(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _submit(value);
  }

  @override
  Widget build(BuildContext context) {
    // Warm the catalogue so suggestions are ready when typing starts.
    ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xs,
              MediaQuery.paddingOf(context).top + AppSpacing.m,
              AppSpacing.xs,
              AppSpacing.m,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: AppSpacing.iconSmall,
                  ),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
                Expanded(
                  child: SearchField(
                    controller: _controller,
                    autofocus: true,
                    outlined: true,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                  ),
                ),
                const IconButton(
                  tooltip: 'Search by photo (coming soon)',
                  onPressed: null,
                  icon: Icon(
                    Icons.photo_camera_outlined,
                    size: AppSpacing.iconBar,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? _IdleView(onPick: _fill)
                : _Suggestions(query: _query.trim(), onPick: _fill),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.query, required this.onPick});

  final String query;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider(query));

    return ListView(
      children: [
        _SuggestionRow(
          text: query,
          query: query,
          trailing: 'Search all',
          onTap: () => onPick(query),
        ),
        for (final Product p in suggestions)
          _SuggestionRow(
            text: p.title,
            query: query,
            trailing: p.category,
            onTap: () => onPick(p.title),
          ),
        if (suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Text(
              'No product names match "$query". Press search to look everywhere.',
              style: AppText.caption.withColor(AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.text,
    required this.query,
    required this.trailing,
    required this.onTap,
  });

  final String text;
  final String query;
  final String trailing;
  final VoidCallback onTap;

  List<TextSpan> _highlight() {
    final lower = text.toLowerCase();
    final start = lower.indexOf(query.toLowerCase());
    final normal = AppText.bodyMedium;
    if (start < 0) return [TextSpan(text: text, style: normal)];
    final end = start + query.length;
    return [
      TextSpan(text: text.substring(0, start), style: normal),
      TextSpan(text: text.substring(start, end), style: AppText.rowTitle),
      TextSpan(text: text.substring(end), style: normal),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceAlt)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.hint),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text.rich(
                TextSpan(children: _highlight()),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(trailing, style: AppText.caption.withColor(AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final trending =
        ref.watch(trendingSearchesProvider).value ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text('Recent searches', style: AppText.cardTitle),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final r in recent)
                Material(
                  color: AppColors.surfaceAlt,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onPick(r),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(r, style: AppText.bodySmall),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (trending.isNotEmpty) ...[
          Text('Trending now', style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.s),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              children: [
                for (var i = 0; i < trending.length; i++)
                  SizedBox(
                    width: constraints.maxWidth / 2,
                    child: InkWell(
                      onTap: () => onPick(trending[i]),
                      borderRadius: AppRadius.tileAll,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${i + 1}',
                                style: AppText.rowTitle.withColor(
                                  i < 3 ? AppColors.warning : AppColors.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                trending[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
