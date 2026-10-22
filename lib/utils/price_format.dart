/// Prix affiché : « 25 € » ou « 12,50 € ».
String formatPrice(double price) {
  final value = price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2).replaceAll('.', ',');
  return '$value €';
}
