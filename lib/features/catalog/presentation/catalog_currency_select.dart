import 'package:flutter/material.dart';

/// Names are generated from ICU Arabic Intl.DisplayNames('currency'),
/// matching frontend CurrencySelect rather than translating ISO codes manually.
class CatalogCurrencySelect extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  const CatalogCurrencySelect({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<CatalogCurrencySelect> createState() => _CatalogCurrencySelectState();
}

class _CatalogCurrencySelectState extends State<CatalogCurrencySelect> {
  bool _customSelected = false;

  @override
  void initState() {
    super.initState();
    _customSelected = isCustom;
  }

  static const names = <String, String>{
    'AED': 'درهم إماراتي',
    'AFN': 'أفغاني',
    'ALL': 'ليك ألباني',
    'AMD': 'درام أرميني',
    'ANG': 'غيلدر أنتيلي هولندي',
    'AOA': 'كوانزا أنغولي',
    'ARS': 'بيزو أرجنتيني',
    'AUD': 'دولار أسترالي',
    'AWG': 'فلورن أروبي',
    'AZN': 'مانات أذربيجان',
    'BAM': 'مارك البوسنة والهرسك قابل للتحويل',
    'BBD': 'دولار بربادوسي',
    'BDT': 'تاكا بنغلاديشي',
    'BGN': 'ليف بلغاري',
    'BHD': 'دينار بحريني',
    'BIF': 'فرنك بروندي',
    'BMD': 'دولار برمودي',
    'BND': 'دولار بروناي',
    'BOB': 'بوليفيانو بوليفي',
    'BRL': 'ريال برازيلي',
    'BSD': 'دولار باهامي',
    'BTN': 'نولتوم بوتاني',
    'BWP': 'بولا بتسواني',
    'BYN': 'روبل بيلاروسي',
    'BZD': 'دولار بليزي',
    'CAD': 'دولار كندي',
    'CDF': 'فرنك كونغولي',
    'CHF': 'فرنك سويسري',
    'CLP': 'بيزو تشيلي',
    'CNY': 'يوان صيني',
    'COP': 'بيزو كولومبي',
    'CRC': 'كولن كوستاريكي',
    'CUC': 'بيزو كوبي قابل للتحويل',
    'CUP': 'بيزو كوبي',
    'CVE': 'اسكودو الرأس الأخضر',
    'CZK': 'كرونة تشيكية',
    'DJF': 'فرنك جيبوتي',
    'DKK': 'كرونة دنماركية',
    'DOP': 'بيزو الدومنيكان',
    'DZD': 'دينار جزائري',
    'EGP': 'جنيه مصري',
    'ERN': 'ناكفا أريتري',
    'ETB': 'بير أثيوبي',
    'EUR': 'يورو',
    'FJD': 'دولار فيجي',
    'FKP': 'جنيه جزر فوكلاند',
    'GBP': 'جنيه إسترليني',
    'GEL': 'لارى جورجي',
    'GHS': 'سيدي غانا',
    'GIP': 'جنيه جبل طارق',
    'GMD': 'دلاسي غامبي',
    'GNF': 'فرنك غينيا',
    'GTQ': 'كوتزال غواتيمالا',
    'GYD': 'دولار غيانا',
    'HKD': 'دولار هونغ كونغ',
    'HNL': 'ليمبيرا هنداروس',
    'HRK': 'كونا كرواتي',
    'HTG': 'جوردى هايتي',
    'HUF': 'فورينت هنغاري',
    'IDR': 'روبية إندونيسية',
    'ILS': 'شيكل إسرائيلي جديد',
    'INR': 'روبية هندي',
    'IQD': 'دينار عراقي',
    'IRR': 'ريال إيراني',
    'ISK': 'كرونة أيسلندية',
    'JMD': 'دولار جامايكي',
    'JOD': 'دينار أردني',
    'JPY': 'ين ياباني',
    'KES': 'شلن كينيي',
    'KGS': 'سوم قيرغستاني',
    'KHR': 'رييال كمبودي',
    'KMF': 'فرنك جزر القمر',
    'KPW': 'وون كوريا الشمالية',
    'KRW': 'وون كوريا الجنوبية',
    'KWD': 'دينار كويتي',
    'KYD': 'دولار جزر كيمن',
    'KZT': 'تينغ كازاخستاني',
    'LAK': 'كيب لاوسي',
    'LBP': 'جنيه لبناني',
    'LKR': 'روبية سريلانكية',
    'LRD': 'دولار ليبيري',
    'LSL': 'لوتي ليسوتو',
    'LYD': 'دينار ليبي',
    'MAD': 'درهم مغربي',
    'MDL': 'ليو مولدوفي',
    'MGA': 'أرياري مدغشقر',
    'MKD': 'دينار مقدوني',
    'MMK': 'كيات ميانمار',
    'MNT': 'توغروغ منغولي',
    'MOP': 'باتاكا ماكاوي',
    'MRU': 'أوقية موريتانية',
    'MUR': 'روبية موريشيوسية',
    'MVR': 'روفيه جزر المالديف',
    'MWK': 'كواشا مالاوي',
    'MXN': 'بيزو مكسيكي',
    'MYR': 'رينغيت ماليزي',
    'MZN': 'متكال موزمبيقي',
    'NAD': 'دولار ناميبي',
    'NGN': 'نايرا نيجيري',
    'NIO': 'قرطبة نيكاراغوا',
    'NOK': 'كرونة نرويجية',
    'NPR': 'روبية نيبالي',
    'NZD': 'دولار نيوزيلندي',
    'OMR': 'ريال عماني',
    'PAB': 'بالبوا بنمي',
    'PEN': 'سول بيروفي',
    'PGK': 'كينا بابوا غينيا الجديدة',
    'PHP': 'بيزو فلبيني',
    'PKR': 'روبية باكستاني',
    'PLN': 'زلوتي بولندي',
    'PYG': 'غواراني باراغواي',
    'QAR': 'ريال قطري',
    'RON': 'ليو روماني',
    'RSD': 'دينار صربي',
    'RUB': 'روبل روسي',
    'RWF': 'فرنك رواندي',
    'SAR': 'ريال سعودي',
    'SBD': 'دولار جزر سليمان',
    'SCR': 'روبية سيشيلية',
    'SDG': 'جنيه سوداني',
    'SEK': 'كرونة سويدية',
    'SGD': 'دولار سنغافوري',
    'SHP': 'جنيه سانت هيلين',
    'SLL': 'ليون سيراليوني - 1964-2022',
    'SOS': 'شلن صومالي',
    'SRD': 'دولار سورينامي',
    'SSP': 'جنيه جنوب السودان',
    'STN': 'دوبرا ساو تومي وبرينسيبي',
    'SVC': 'كولون سلفادوري',
    'SYP': 'ليرة سورية',
    'SZL': 'ليلانجيني سوازيلندي',
    'THB': 'باخت تايلاندي',
    'TJS': 'سوموني طاجيكستاني',
    'TMT': 'مانات تركمانستان',
    'TND': 'دينار تونسي',
    'TOP': 'بانغا تونغا',
    'TRY': 'ليرة تركية',
    'TTD': 'دولار ترينداد وتوباغو',
    'TWD': 'دولار تايواني',
    'TZS': 'شلن تنزاني',
    'UAH': 'هريفنيا أوكراني',
    'UGX': 'شلن أوغندي',
    'USD': 'دولار أمريكي',
    'UYU': 'بيزو اوروغواي',
    'UZS': 'سوم أوزبكستاني',
    'VES': 'بوليفار فنزويلي',
    'VND': 'دونج فيتنامي',
    'VUV': 'فاتو فانواتو',
    'WST': 'تالا ساموا',
    'XAF': 'فرنك وسط أفريقي',
    'XCD': 'دولار شرق الكاريبي',
    'XDR': 'حقوق السحب الخاصة',
    'XOF': 'فرنك غرب أفريقي',
    'XPF': 'فرنك سي إف بي',
    'XSU': 'XSU',
    'YER': 'ريال يمني',
    'ZAR': 'راند جنوب أفريقيا',
    'ZMW': 'كواشا زامبي',
    'ZWL': 'دولار زمبابوي 2009',
  };

  bool get isCustom =>
    widget.controller.text.trim().isNotEmpty &&
      !names.containsKey(widget.controller.text.trim().toUpperCase());

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.trim().toUpperCase();
    final selected = (_customSelected || isCustom) ? '__custom' :
      code.isEmpty ? null : code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('currency-select-' + (selected ?? 'none')),
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'العملة',
            border: OutlineInputBorder(),
          ),
          hint: const Text('اختر العملة'),
          items: [
            for (final entry in names.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value,
                  overflow: TextOverflow.ellipsis),
              ),
            const DropdownMenuItem(
              value: '__custom', child: Text('عملة أخرى'),
            ),
          ],
          onChanged: widget.enabled ? (value) {
            if (value == null) return;
            setState(() {
              if (value == '__custom') {
                _customSelected = true;
                if (!isCustom) widget.controller.clear();
              } else {
                _customSelected = false;
                widget.controller.text = value;
              }
            });
          } : null,
        ),
        if (selected == '__custom') ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            decoration: const InputDecoration(
              labelText: 'رمز العملة (3 أحرف)',
              hintText: 'مثل: YER',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}
