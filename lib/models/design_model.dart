class DesignModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> tags;
  final bool isFavorite;

  DesignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.tags,
    this.isFavorite = false,
  });
}

// 샘플 데이터
List<DesignModel> sampleDesigns = [
  DesignModel(
    id: '1',
    title: '머티리얼 디자인 3 - 기본 레이아웃',
    description: '머티리얼 디자인 3의 기본 레이아웃 구성을 보여주는 디자인입니다. 카드, 버튼, 아이콘 등의 기본 요소들이 포함되어 있습니다.',
    imageUrl: 'https://lh3.googleusercontent.com/3hGj9Qtw0WbR2U3ARQQxS9Y9Ty8H2Bx_uUJQO4JLz32m_tSiR9CoYBulHpizEH6zyA0=w412-h220-rw',
    category: '머티리얼 디자인',
    tags: ['머티리얼 3', '레이아웃', '기본 요소'],
  ),
  DesignModel(
    id: '2',
    title: '소셜 미디어 앱 UI',
    description: '현대적인 소셜 미디어 앱을 위한 안드로이드 UI 디자인입니다. 피드, 프로필, 댓글 등의 화면이 포함되어 있습니다.',
    imageUrl: 'https://cdn.dribbble.com/users/1445352/screenshots/17352881/media/027e9d0eb557131d9a0b56cc456c0c74.jpg',
    category: '소셜 미디어',
    tags: ['SNS', '피드', '프로필'],
  ),
  DesignModel(
    id: '3',
    title: '금융 앱 대시보드',
    description: '금융 정보를 시각적으로 보여주는 안드로이드 앱 대시보드 디자인입니다. 차트, 그래프, 수치 표시 등이 포함되어 있습니다.',
    imageUrl: 'https://cdn.dribbble.com/users/2142762/screenshots/15501855/media/9f2463564a089806611e48131f1ed0d7.jpg',
    category: '금융',
    tags: ['대시보드', '차트', '그래프'],
  ),
  DesignModel(
    id: '4',
    title: '쇼핑 앱 UI 키트',
    description: '온라인 쇼핑몰을 위한 안드로이드 앱 UI 키트입니다. 상품 목록, 상세 페이지, 장바구니 등이 포함되어 있습니다.',
    imageUrl: 'https://cdn.dribbble.com/users/4189231/screenshots/17037522/media/fbbe8f3ddbbf2c6225ff7aaf34a28cf4.png',
    category: '쇼핑',
    tags: ['이커머스', '상품 목록', '장바구니'],
  ),
  DesignModel(
    id: '5',
    title: '음악 플레이어 앱',
    description: '모던한 디자인의 음악 플레이어 안드로이드 앱입니다. 플레이어 화면, 재생 목록, 아티스트 페이지 등이 포함되어 있습니다.',
    imageUrl: 'https://cdn.dribbble.com/users/4189231/screenshots/15583528/media/a5fdce3a63aa7f64ba2340e81ff82a68.png',
    category: '엔터테인먼트',
    tags: ['음악', '플레이어', '오디오'],
  ),
  DesignModel(
    id: '6',
    title: '여행 앱 UI',
    description: '여행자를 위한 안드로이드 앱 UI 디자인입니다. 목적지 탐색, 호텔 예약, 일정 관리 등의 화면이 포함되어 있습니다.',
    imageUrl: 'https://cdn.dribbble.com/users/1998175/screenshots/15820547/media/b99a9c3df4fec32e2d1c2f70bbac823f.jpg',
    category: '여행',
    tags: ['예약', '일정', '목적지'],
  ),
];

// 카테고리 목록
List<String> designCategories = [
  '모두',
  '머티리얼 디자인',
  '소셜 미디어',
  '금융',
  '쇼핑',
  '엔터테인먼트',
  '여행',
]; 