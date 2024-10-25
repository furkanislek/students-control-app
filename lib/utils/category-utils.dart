// ignore: file_names
String getCategoryString(int categoryId) {
  switch (categoryId) {
    case 1:
      return 'Matematik';
    case 2:
      return 'Fizik';
    case 3:
      return 'Kimya';
    case 4:
      return 'Türkçe';
    case 5:
      return 'Edebiyat';
    case 6:
      return 'Geometri';
    case 7:
      return 'Biyoloji';
    case 8:
      return 'Sosyal Bilgiler';
    default:
      return 'Bilinmeyen Kategori';
  }
}
