# 盈亏比组合管理工具

该项目是一款用于**计算盈亏比、管理多标的交易规则**的 Flutter 应用。背景来源于资金管理需求：在可承受亏损范围内，通过买入价/止损价/盈亏比快速推导仓位、所需本金与止盈目标，并将常用规则保存到后端方便复用。

## 功能概览
- 批量添加个股（名称 + 代码），输入买入点、止损点、最大可亏金额与盈亏比；
- 行内一键调用后端 `/api/calc` 接口，得到单位风险、可买入数量、所需本金、最大收益和止盈价；
- 支持保存/删除规则，实时同步 `/api/rules` 列表，便于集中管理；
- 长按下拉刷新远端规则，客户端内含错误提示与加载状态。

## 启动方式
1. **准备环境**
   - 安装 Flutter 3.10+（或满足 `pubspec.yaml` 中 `sdk >= 3.1.0 < 4.0.0` 要求）。
   - 本地或远端部署提供以下 REST 接口的服务：
     - `POST /api/calc`：接受计算参数，返回盈亏结果；
     - `GET /api/rules`：返回保存的规则列表；
     - `POST /api/rules`：保存一条规则；
     - `DELETE /api/rules/{id}`：删除规则。
   - 若后端地址不同，请修改 `lib/main.dart` 顶部的 `apiBaseUrl`。

2. **安装依赖并运行**
   ```bash
   flutter pub get
   flutter run
   ```
   可通过 `flutter run -d chrome`、`-d windows` 等参数指定目标平台。

## 目录结构说明
- `lib/main.dart`：应用入口及主要 UI 逻辑，包含动态表单、结果展示与规则列表。
- `lib/models/calc_models.dart`：与后端交互的数据模型（请求、结果、规则）。
- `lib/services/api_service.dart`：封装 HTTP 调用、错误处理与客户端复用。
- 其余平台目录（`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`）由 Flutter 自动生成。

## 其他
- 需要根据自身风控逻辑调整字段校验与显示格式。
- 建议在 README 中补充后端接口示例及认证方式（若存在）。
