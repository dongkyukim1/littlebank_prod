import 'package:flutter/material.dart';

class ParentBankSelectionModal extends StatefulWidget {
  final bool isBankTab;
  final Function(bool) onTabChanged;
  final List<Map<String, String>> banks;
  final List<Map<String, String>> securities;
  final Function(String) onBankSelected;

  const ParentBankSelectionModal({
    super.key,
    required this.isBankTab,
    required this.onTabChanged,
    required this.banks,
    required this.securities,
    required this.onBankSelected,
  });

  @override
  State<ParentBankSelectionModal> createState() => _ParentBankSelectionModalState();
}

class _ParentBankSelectionModalState extends State<ParentBankSelectionModal> {
  String searchText = '';
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 필터링된 아이템 가져오기
    final items = widget.isBankTab ? widget.banks : widget.securities;
    List<Map<String, String>> filteredItems = [];

    if (searchText.isEmpty) {
      filteredItems = List.from(items);
    } else {
      final query = searchText.toLowerCase();
      filteredItems =
          items
              .where((item) => item['name']!.toLowerCase().contains(query))
              .toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 1,
                        child: Text(
                          '돈을 어떤 곳으로 보낼까요?',
                          style: TextStyle(
                            color: const Color(0xFF202020),
                            fontSize: 16,
                            fontFamily: 'Pretendard-Bold',
                            letterSpacing: -0.72,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 은행/증권사 탭
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.isBankTab) {
                            widget.onTabChanged(true);
                            Navigator.pop(context);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '은행',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    widget.isBankTab
                                        ? Colors.black
                                        : const Color(0xFFC4C4C4),
                                fontSize: 14,
                                fontFamily:
                                    widget.isBankTab
                                        ? 'Pretendard-Bold'
                                        : 'Pretendard-Light',
                                letterSpacing: -0.32,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 2,
                              color:
                                  widget.isBankTab
                                      ? Colors.black
                                      : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isBankTab) {
                            widget.onTabChanged(false);
                            Navigator.pop(context);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '증권사',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    !widget.isBankTab
                                        ? Colors.black
                                        : const Color(0xFFC4C4C4),
                                fontSize: 14,
                                fontFamily:
                                    !widget.isBankTab
                                        ? 'Pretendard-Bold'
                                        : 'Pretendard-Light',
                                letterSpacing: -0.32,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 2,
                              color:
                                  !widget.isBankTab
                                      ? Colors.black
                                      : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 검색 바
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.white),
            child: Container(
              height: 48,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.80, color: const Color(0xFF8096BA)),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icons/Icon/검색/Regular.png',
                      width: 24,
                      height: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintText: '찾고싶은 계좌를 입력해 주세요',
                          hintStyle: TextStyle(
                            color: const Color(0xFF999999),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                    if (searchText.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            searchText = '';
                            searchController.clear();
                          });
                        },
                        child: Icon(
                          Icons.cancel,
                          color: Color(0xFF8096BA),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 은행/증권사 그리드
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child:
                  filteredItems.isEmpty && searchText.isNotEmpty
                      ? Center(
                        child: Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            color: const Color(0xFF8490A3),
                            fontSize: 14,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                      )
                      : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onBankSelected(item['name']!);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6F8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        item['logo']!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.contain,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        item['name']!,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xFF353535),
                                          fontSize: 10,
                                          fontFamily: 'Pretendard-Light',
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
} 