import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/design_model.dart';

class DesignDetailScreen extends StatelessWidget {
  final DesignModel design;

  const DesignDetailScreen({
    super.key,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(design.title),
        actions: [
          IconButton(
            icon: Icon(
              design.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: design.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              // 즐겨찾기 토글 기능 구현 (실제 앱에서는 상태 관리 추가)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('즐겨찾기 기능 준비 중입니다')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 공유 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공유 기능 준비 중입니다')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 헤더
            Stack(
              children: [
                // 이미지
                Hero(
                  tag: 'design_image_${design.id}',
                  child: CachedNetworkImage(
                    imageUrl: design.imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                // 그라데이션 오버레이
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 카테고리 정보
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Chip(
                    label: Text(
                      design.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            
            // 콘텐츠 섹션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    design.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 설명
                  Text(
                    design.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 태그 섹션
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '태그',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: design.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // UI 컴포넌트 섹션 (실제로는 해당 디자인에 맞는 컴포넌트 보여주기)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UI 컴포넌트',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 버튼 예시
                      const Text('버튼'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('기본 버튼'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('아웃라인 버튼'),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('텍스트 버튼'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 텍스트 필드 예시
                      const Text('입력 필드'),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          labelText: '텍스트 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 카드 예시
                      const Text('카드'),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '카드 제목',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text('카드 내용이 여기에 들어갑니다. 다양한 정보를 표시할 수 있습니다.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 코드 보기 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('코드 보기 기능 준비 중입니다')),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('코드 보기'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 미리보기 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('앱 미리보기 기능 준비 중입니다')),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('앱 미리보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 