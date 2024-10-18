// Define an enum for the categories
enum QuestionCategory  {
  Matematik(1),
  Fizik(2),
  Kimya(3),
  Turkce(4),
  Edebiyat(5),
  Geometri(6),
  Biyoloji(7),
  SosyalBilgiler(8);

  final int id;
  const QuestionCategory(this.id);
}
