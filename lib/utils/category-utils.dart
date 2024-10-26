// ignore: file_names
String getCategoryString(int categoryId) {
  switch (categoryId) {
    case 0:
      return 'Matematik';
    case 1:
      return 'Fizik';
    case 2:
      return 'Kimya';
    case 3:
      return 'Türkçe';
    case 4:
      return 'Edebiyat';
    case 5:
      return 'Geometri';
    case 6:
      return 'Biyoloji';
    case 7:
      return 'Sosyal Bilgiler';
    default:
      return 'Bilinmeyen Kategori';
  }
}
