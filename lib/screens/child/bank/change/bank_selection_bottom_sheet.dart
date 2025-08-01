import 'package:flutter/material.dart';

class BankSelectionBottomSheet extends StatefulWidget {
  final Function(String bankName, String bankCode) onBankSelected;

  const BankSelectionBottomSheet({super.key, required this.onBankSelected});

  @override
  State<BankSelectionBottomSheet> createState() =>
      _BankSelectionBottomSheetState();
}

class _BankSelectionBottomSheetState extends State<BankSelectionBottomSheet> {
  String searchText = '';
  TextEditingController searchController = TextEditingController();
  bool isBankTab = true;

  // 은행 목록 (사용자 지정 순서)
  final List<Map<String, String>> banks = [
    {'name': '국민', 'code': '004', 'logo': 'assets/logos/kb_bank.png'},
    {'name': '신한', 'code': '088', 'logo': 'assets/logos/shinhan_bank.png'},
    {'name': '농협', 'code': '011', 'logo': 'assets/logos/nh_bank.png'},
    {'name': '하나', 'code': '081', 'logo': 'assets/logos/hana_bank.png'},
    {'name': '우리', 'code': '020', 'logo': 'assets/logos/woori_bank.png'},
    {'name': '카카오', 'code': '090', 'logo': 'assets/logos/kakao_bank.png'},
    {'name': '경남', 'code': '039', 'logo': 'assets/logos/kyongnam_bank.png'},
    {'name': '광주', 'code': '034', 'logo': 'assets/logos/gwangju_bank.png'},
    {'name': '기업', 'code': '003', 'logo': 'assets/logos/ibk_bank.png'},
    {'name': '대구', 'code': '031', 'logo': 'assets/logos/daegu_bank.png'},
    {'name': '부산', 'code': '032', 'logo': 'assets/logos/busan_bank.png'},
    {'name': '산업', 'code': '002', 'logo': 'assets/logos/KBD_BANK.png'},
    {'name': '수협', 'code': '007', 'logo': 'assets/logos/suhyup_bank.png'},
    {'name': '신협', 'code': '048', 'logo': 'assets/logos/shinhyup.png'},
    {'name': 'KEB 외환', 'code': '005', 'logo': 'assets/logos/keb_bank.png'},
    {'name': '우체국', 'code': '071', 'logo': 'assets/logos/우체국_bank.png'},
    {'name': '전북', 'code': '037', 'logo': 'assets/logos/jeonbuk_bank.png'},
    {'name': '제주', 'code': '035', 'logo': 'assets/logos/jeju_bank.png'},
    {'name': '축협', 'code': '012', 'logo': 'assets/logos/축협_bank.png'},
    {'name': '케이뱅크', 'code': '089', 'logo': 'assets/logos/kbank.png'},
    {'name': '한국씨티', 'code': '027', 'logo': 'assets/logos/citi_bank.png'},
    {'name': 'SC제일', 'code': '023', 'logo': 'assets/logos/sc_bank.png'},
  ];

  // 증권사 목록 (parent_account_link_screen.dart와 동일한 순서)
  final List<Map<String, String>> securities = [
    {'name': '미래에셋증권', 'code': '230', 'logo': 'assets/logos/mirae_asset.png'},
    {
      'name': '삼성증권',
      'code': '240',
      'logo': 'assets/logos/samsung_securities.png',
    },
    {
      'name': '한국투자증권',
      'code': '243',
      'logo': 'assets/logos/korea_investment.png',
    },
    {'name': '키움증권', 'code': '264', 'logo': 'assets/logos/kiwoom.png'},
    {'name': '대신증권', 'code': '267', 'logo': 'assets/logos/daishin.png'},
    {'name': 'NH투자증권', 'code': '289', 'logo': 'assets/logos/nh_investment.png'},
    {
      'name': '신한투자증권',
      'code': '278',
      'logo': 'assets/logos/shinhan_investment.png',
    },
    {'name': 'KB증권', 'code': '218', 'logo': 'assets/logos/kb_securities.png'},
    {'name': '토스증권', 'code': '271', 'logo': 'assets/logos/toss_securities.png'},
    {
      'name': '카카오페이증권',
      'code': '288',
      'logo': 'assets/logos/kakaopay_securities.png',
    },
    {'name': '나무증권', 'code': '299', 'logo': 'assets/logos/namoo.jpg'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 현재 탭에 따른 아이템 목록
    final items = isBankTab ? banks : securities;

    // 검색 필터링
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
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 헤더 영역
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '계좌를 변경할 금융기관을 선택하세요',
                    style: TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 16,
                      fontFamily: 'Pretendard-Bold',
                      letterSpacing: -0.32,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    child: Icon(Icons.close, size: 24, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          // 은행/증권사 탭
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isBankTab = true;
                        searchText = '';
                        searchController.clear();
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          '은행',
                          style: TextStyle(
                            color: isBankTab ? Colors.black : Color(0xFFC4C4C4),
                            fontSize: 14,
                            fontFamily:
                                isBankTab
                                    ? 'Pretendard-Bold'
                                    : 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: isBankTab ? Colors.black : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isBankTab = false;
                        searchText = '';
                        searchController.clear();
                      });
                    },
                    child: Column(
                      children: [
                        Text(
                          '증권사',
                          style: TextStyle(
                            color:
                                !isBankTab ? Colors.black : Color(0xFFC4C4C4),
                            fontSize: 14,
                            fontFamily:
                                !isBankTab
                                    ? 'Pretendard-Bold'
                                    : 'Pretendard-Light',
                            letterSpacing: -0.28,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: !isBankTab ? Colors.black : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 검색 바
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 44,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 0.80, color: Color(0xFF8096BA)),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 24, color: Color(0xFF8096BA)),
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
                          hintText:
                              isBankTab
                                  ? '연결하고 싶은 은행을 검색해주세요'
                                  : '연결하고 싶은 증권사를 검색해주세요',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                            fontFamily: 'Pretendard-Light',
                            letterSpacing: -0.24,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Pretendard-Light',
                          letterSpacing: -0.24,
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
              padding: EdgeInsets.symmetric(vertical: 16),
              child:
                  filteredItems.isEmpty && searchText.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Color(0xFFCCCCCC),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(
                                color: Color(0xFF8490A3),
                                fontSize: 14,
                                fontFamily: 'Pretendard-Light',
                                letterSpacing: -0.28,
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onBankSelected(
                                item['name']!,
                                item['code']!,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE4ECF8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: ShapeDecoration(
                                      shape: OvalBorder(),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        item['logo']!,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: 44,
                                            height: 44,
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.account_balance,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Text(
                                      item['name']!,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF202020),
                                        fontSize: 10,
                                        fontFamily: 'Pretendard-Light',
                                        letterSpacing: -0.24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
