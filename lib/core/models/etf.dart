enum EtfSymbol { world, emerging, bonds }

extension EtfSymbolX on EtfSymbol {
  String get label {
    switch (this) {
      case EtfSymbol.world:
        return 'MSCI World';
      case EtfSymbol.emerging:
        return 'Emerging Markets';
      case EtfSymbol.bonds:
        return 'Global Aggregate Bonds';
    }
  }

  String get code {
    switch (this) {
      case EtfSymbol.world:
        return 'WORLD';
      case EtfSymbol.emerging:
        return 'EM';
      case EtfSymbol.bonds:
        return 'BONDS';
    }
  }

  static EtfSymbol fromCode(String code) {
    switch (code) {
      case 'WORLD':
        return EtfSymbol.world;
      case 'EM':
        return EtfSymbol.emerging;
      case 'BONDS':
        return EtfSymbol.bonds;
      default:
        return EtfSymbol.world;
    }
  }
}
