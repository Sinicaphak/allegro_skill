# Allegro 17.2 器件清单导出

脚本会遍历当前设计根对象的全部 `components`，包括顶层、底层和未放置器件，并生成 Excel 可直接打开的 CSV 文件。

## 导出列

| 列名 | 17.2 数据来源 | 含义 |
|---|---|---|
| RefDes | `component->name` | 位号，如 R1、U20 |
| DeviceType | `component->deviceType` | 器件名称/器件类型 |
| PartNumber | `component->compdef` 的 `PART_NUMBER` 属性 | 料号；未维护时留空 |
| PackageHeightMax | 实际安装面对应的 placebound | 主高度列，保留原始单位；未维护时留空 |
| PackageHeightSource | 高度来源层 | 标明 TOP 或 BOTTOM；未维护时留空 |
| Package | `component->package` | 封装名称 |
| Class | `component->class` | 器件分类 |
| Placed | `component->symbol` | 是否已经放置 |
| BoardSide | `component->symbol->isMirrored` | 实际安装面：TOP、BOTTOM 或 UNPLACED |
| SymbolName | `component->symbol->name` | 已放置的封装符号名称 |
| X / Y | `component->symbol->xy` | 放置坐标 |
| Rotation | `component->symbol->rotation` | 旋转角度 |
| Mirrored | `component->symbol->isMirrored` | 是否镜像/位于背面 |
| PlaceBoundTopCount | TOP placebound 图形 | 找到的 TOP placebound 数量 |
| PlaceBoundTopPackageHeightMax | TOP placebound 的 `PACKAGE_HEIGHT_MAX` | 保留原值及单位；未维护时留空 |
| PlaceBoundBottomCount | BOTTOM placebound 图形 | 找到的 BOTTOM placebound 数量 |
| PlaceBoundBottomPackageHeightMax | BOTTOM placebound 的 `PACKAGE_HEIGHT_MAX` | 保留原值及单位；未维护时留空 |

## 加载和运行

在 Allegro 17.2 中打开 `.brd` 设计，然后加载：

```lisp
load("E:/Ruijie/损耗计算/output/skill/export_components_17_2/export_components_17_2.il")
load("E:/RjDir/UserData/Desktop/height_check/skill/lyh_0730/export_components_17_2.il")
```
E:\RjDir\UserData\Desktop\height_check\skill\lyh_0730
加载成功会显示：

```text
Loaded command: rj_export_components
```

随后在 Allegro 命令行运行：

```text
rj_export_components
```

选择保存位置后生成 `component_list.csv`。直接使用 Excel 打开即可，每行对应一个器件，默认按位号排序。

## 说明

- 此脚本只读取 PCB 数据库，不修改设计，也不会自动保存 `.brd`。
- 如果取消保存对话框，脚本直接结束。
- CSV 对包含逗号或双引号的字段进行了转义。
- 输出是 Excel 兼容 CSV，不是二进制 `.xlsx`，因此不依赖本机安装 Excel。
- `PART_NUMBER` 不存在时留空，不会使用 `VALUE` 或 `DeviceType` 猜测。
- placebound 存在但没有 `PACKAGE_HEIGHT_MAX` 时高度列留空，不会填写 0。
- 脚本同时扫描封装实例和封装定义，识别以 `PLACE_BOUND_TOP` 或 `PLACE_BOUND_BOTTOM` 结尾的层名。
- 如果同一侧有多个不同的高度值，会在一个单元格中用 `; ` 分隔，便于发现封装数据不一致。
- 顶层器件的主高度只取 TOP，底层器件只取 BOTTOM，不从另一侧猜测或回填。另一侧的原始值仍保留在审计列中。
