import 'insight_context.dart';

InsightContext mapCategoryToContext(String category) {
  switch (category.toLowerCase()) {
    case 'dukkan':
    case 'ofis':
    case 'isletme':
      return InsightContext.business;
    case 'ev':
      return InsightContext.homeOffice;
    case 'kadin':
    case 'erkek':
      return InsightContext.fashion;
    case 'sac':
    case 'guzellik':
      return InsightContext.beautyHair;
    default:
      return InsightContext.general;
  }
}