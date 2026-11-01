class ObdMessage {
  const ObdMessage(this.ecu, this.data, {this.can = false});
  final bool can;
  final String ecu;
  final List<int> data;
}
