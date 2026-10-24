import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'brands.dart';
import 'categories.dart';
import 'device_apps.dart';
import 'store.dart';
import 'theme.dart';
import 'utils.dart';

/// The ribbon "S" path from the app icon, in the icon's 64×64 coordinate space.
Path _ribbon() => Path()
  ..moveTo(51, 12)
  ..lineTo(24, 12)
  ..cubicTo(15, 12, 12.5, 23, 20, 27)
  ..lineTo(41, 37.5)
  ..cubicTo(48, 41, 46.5, 49.5, 39, 49.5)
  ..lineTo(13, 49.5);

/// The "S" as a single-colour glyph (wordmark, tab bar).
class SMark extends StatelessWidget {
  const SMark({super.key, this.size = 20, this.color = C.ink});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SMarkPainter(color));
}

class _SMarkPainter extends CustomPainter {
  _SMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Crop to the glyph's own box (8..56 × 7..55) so it lines up with text.
    canvas.scale(size.width / 48);
    canvas.translate(-8, -7);
    canvas.drawPath(
      _ribbon(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SMarkPainter old) => old.color != color;
}

/// The full-colour app icon: mint tile, orange ribbon, soft reflection.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _AppIconPainter());
}

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final tile = RRect.fromLTRBR(1, 1, 63, 63, const Radius.circular(15));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF2EE), Color(0xFFC8D1CB)],
        ).createShader(tile.outerRect),
    );
    canvas.drawRRect(
      tile,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFB9C3BC),
    );
    canvas.drawPath(
      _ribbon(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(colors: [Color(0xFFFF2E12), Color(0xFFFF7A1A)])
            .createShader(const Rect.fromLTWH(8, 7, 48, 48)),
    );
    const reflect = Rect.fromLTWH(13, 54, 27, 6);
    canvas.drawRect(
      reflect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x73FF6A1A), Color(0x00FF6A1A)],
        ).createShader(reflect),
    );
  }

  @override
  bool shouldRepaint(_AppIconPainter old) => false;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.scale = 1});
  final double scale;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Spent',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(padding: EdgeInsets.only(bottom: 3 * scale), child: SMark(size: 18 * scale)),
            Text('pent', style: t(23 * scale, FontWeight.w800, height: 1, tracking: -1 * scale)),
          ],
        ),
      );
}

/// "● Overview" style label.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color = C.ink, this.size = 13});
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: t(size, FontWeight.w600, color: color), overflow: TextOverflow.ellipsis)),
        ],
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: softShadow),
        child: child,
      );
}

/// A tappable surface with a gentle press-scale instead of a Material ripple.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        label: widget.semanticLabel,
        child: MouseRegion(
          cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            child: AnimatedScale(
              scale: _down ? 0.97 : 1,
              duration: const Duration(milliseconds: 120),
              child: widget.child,
            ),
          ),
        ),
      );
}

class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.onTap, required this.label, this.background = C.pill, this.color = C.ink, this.shadow = false, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color background;
  final Color color;
  final bool shadow;
  final bool badge;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle, boxShadow: shadow ? softShadow : null),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              if (badge)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: C.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

/// Back button + centred title, as on the Notifications mockup.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 70),
              child: Text(title, style: t(22, FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Positioned(
              left: 20,
              child: RoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            if (trailing != null) Positioned(right: 20, child: trailing!),
          ],
        ),
      );
}

/// An SVG asset drawn in a single colour.
class TintedSvg extends StatelessWidget {
  const TintedSvg(this.asset, {super.key, required this.color, required this.size});
  final String asset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.categoryId, {super.key, this.size = 44});
  final String categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = categoryOf(categoryId);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
      child: TintedSvg(c.icon, color: c.color, size: size * 0.45),
    );
  }
}

/// A merchant's official logo in its brand colour, on a soft tint of that colour.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar(this.brand, {super.key, this.size = 44});
  final Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.alphaBlend(brand.color.withValues(alpha: 0.12), Colors.white),
          shape: BoxShape.circle,
        ),
        child: TintedSvg(brand.asset, color: brand.color, size: size * 0.48),
      );
}

/// A payment app's logo: the real launcher icon from the phone when we have it (Android),
/// otherwise its official mark, otherwise a tinted initial.
class AppLogo extends StatelessWidget {
  const AppLogo(this.app, {super.key, this.size = 40});
  final PaymentApp app;
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: DeviceApps.icons,
        builder: (_, icons, _) {
          final png = icons[app.package];
          if (png != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.26),
              child: Image.memory(png, width: size, height: size, gaplessPlayback: true),
            );
          }
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.26),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: app.logo != null
                ? TintedSvg(app.logo!, color: app.color, size: size * 0.6)
                : Text(app.name[0], style: t(size * 0.45, FontWeight.w800, color: app.color)),
          );
        },
      );
}

/// Merchant logo (or category icon), with the payment app it went through as a badge.
class TxnAvatar extends StatelessWidget {
  const TxnAvatar(this.txn, {super.key, this.size = 44});
  final Txn txn;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = brandFor(txn.title);
    final app = paymentApp(txn.app);
    final main = brand != null ? BrandAvatar(brand, size: size) : CategoryAvatar(txn.categoryId, size: size);
    if (app == null) return main;
    final badge = size * 0.42;
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        children: [
          main,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(badge * 0.3)),
              child: AppLogo(app, size: badge),
            ),
          ),
        ],
      ),
    );
  }
}

String money(BuildContext context, double amount, {bool cents = false}) =>
    formatMoney(amount, SpentScope.of(context).money, forceCents: cents);

/// Cents only when the amount has them (€25.50, but €750).
String moneyExact(BuildContext context, double amount) =>
    money(context, amount, cents: amount != amount.roundToDouble());

class TxnRow extends StatelessWidget {
  const TxnRow(this.entry, {super.key, this.onTap});
  final Entry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry.txn;
    final c = categoryOf(e.categoryId);
    final app = paymentApp(e.app);
    final via = app != null
        ? ' · ${app.name}'
        : switch (e.source) {
            TxSource.upi => ' · UPI',
            TxSource.message => ' · Imported',
            TxSource.detected => ' · Auto',
            TxSource.manual => '',
          };
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            TxnAvatar(e),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: t(15, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${c.name} · ${shortDate(entry.date)}$via',
                      style: t(13, FontWeight.w400, color: C.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (e.recurring) Text('Recurring', style: t(13, FontWeight.w400, color: C.inkMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${e.isExpense ? '' : '+'}${moneyExact(context, e.amount)}',
              style: t(15, FontWeight.w700, color: e.isExpense ? C.ink : C.income),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spending split by category (income is left out — it isn't spending).
class CategoryBars extends StatelessWidget {
  const CategoryBars(this.entries, {super.key, this.limit});
  final List<Entry> entries;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final en in entries.where((e) => e.txn.isExpense)) {
      totals.update(en.txn.categoryId, (v) => v + en.txn.amount, ifAbsent: () => en.txn.amount);
    }
    final sum = totals.values.fold(0.0, (a, b) => a + b);
    var rows = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (limit != null) rows = rows.take(limit!).toList();
    if (rows.isEmpty) return const EmptyNote('No spending this month yet.');

    return Column(
      children: [
        for (final r in rows) ...[
          _bar(context, categoryOf(r.key), r.value, sum == 0 ? 0 : r.value / sum),
          if (r != rows.last) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _bar(BuildContext context, Category c, double amount, double share) => Column(
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(c.name, style: t(13, FontWeight.w600, color: c.color))),
              Text('${(share * 100).round()}%', style: t(13, FontWeight.w400, color: C.inkMuted)),
              const SizedBox(width: 6),
              Text(money(context, amount, cents: true), style: t(15, FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(height: 6, color: C.pill),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share.clamp(0.015, 1.0)),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(text, textAlign: TextAlign.center, style: t(14, FontWeight.w400, color: C.inkFaint))),
      );
}

/// Large rounded pill, used for selectors, sheet buttons and primary actions.
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, required this.onTap, this.background = C.pill, this.color = C.ink, this.height = 48, this.icon});
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color color;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.55 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: t(15, FontWeight.w600, color: color), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      );
}

/// The pill-shaped text input used across forms.
class PillField extends StatelessWidget {
  const PillField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final int maxLines;
  final TextCapitalization capitalization;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        maxLines: maxLines,
        textCapitalization: capitalization,
        style: t(15, FontWeight.w500),
        cursorColor: C.brand,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: t(15, FontWeight.w400, color: C.inkFaint),
          prefixIcon: icon == null ? null : Icon(icon, size: 20, color: C.inkFaint),
          suffixIcon: suffix,
          filled: true,
          fillColor: C.pill,
          contentPadding: EdgeInsets.symmetric(horizontal: icon == null ? 20 : 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(maxLines == 1 ? 99 : 22),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: t(14, FontWeight.w500, color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    ));
}
