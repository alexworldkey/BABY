// 烟雾测试（widget_test.dart）
//
// 这里是 Flutter 项目 `flutter create`/CI 第一次跑 `flutter analyze` 时
// 必须要有的测试文件，否则会用默认模板引用不存在的 `MyApp` 类导致
// analyze 失败。改写为纯数据层单元测试，避免触发任何 platform channel
// （audio/confetti/speech），保证 CI 跑得稳定。

import 'package:flutter_test/flutter_test.dart';
import 'package:baby_english/services/fruit_data.dart';

void main() {
  test('水果数据加载正常', () {
    expect(FruitData.all.length, 4);
    expect(FruitData.byId('apple')?.chineseName, '苹果');
    expect(FruitData.byId('lemon')?.chineseName, '柠檬');
    expect(FruitData.byId('orange')?.chineseName, '橙子');
    expect(FruitData.byId('strawberry')?.chineseName, '草莓');
  });

  test('水果英文名小写匹配键正确', () {
    expect(FruitData.byId('apple')?.matchKey, 'apple');
    expect(FruitData.byId('strawberry')?.matchKey, 'strawberry');
  });

  test('无效 id 返回 null', () {
    expect(FruitData.byId('not_exist'), isNull);
  });
}
