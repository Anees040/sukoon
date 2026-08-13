import 'package:flutter/material.dart';

import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/city_repository.dart';
import 'package:sukoon/features/cities/city_detail.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/theme.dart';

/// Prayer times for ~100 Pakistani cities — fully offline, searchable in
/// English and Urdu, with favorites pinned on top.
class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final Future<List<City>> _future = CityRepository.all();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.citiesTitle)),
      body: SafeArea(
        child: FutureBuilder<List<City>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            return ValueListenableBuilder<int>(
              valueListenable: Prefs.revision,
              builder: (context, _, __) {
                final filtered = CityRepository.search(all, _query);
                final favIds = Prefs.favoriteCities.toSet();
                final favs = _query.trim().isEmpty
                    ? [
                        for (final c in all)
                          if (favIds.contains(c.id)) c
                      ]
                    : const <City>[];

                return ListView(
                  padding: kScreenPad,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: l10n.citiesSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: SukoonColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (favs.isNotEmpty) ...[
                      Text(l10n.citiesFavorites,
                          style: t.labelMedium
                              ?.copyWith(color: SukoonColors.accent)),
                      for (final c in favs)
                        _CityRow(city: c, isFavorite: true),
                      const SizedBox(height: 10),
                      Text(l10n.citiesAll,
                          style: t.labelMedium?.copyWith(
                              color: SukoonColors.textSecondary)),
                    ],
                    for (final c in filtered)
                      _CityRow(
                          city: c, isFavorite: favIds.contains(c.id)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.isFavorite});

  final City city;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final isUrdu = l10n.localeName == 'ur';
    final primary = isUrdu ? city.nameUr : city.nameEn;
    final secondary = isUrdu ? city.nameEn : city.nameUr;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(primary, style: t.titleMedium),
      subtitle: Text(secondary,
          style: t.bodySmall?.copyWith(color: SukoonColors.textFaint)),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: isFavorite ? SukoonColors.warning : SukoonColors.textFaint,
        ),
        onPressed: () => Prefs.toggleFavoriteCity(city.id),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CityDetail(city: city)),
      ),
    );
  }
}
