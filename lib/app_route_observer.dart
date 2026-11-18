import 'package:flutter/material.dart';

/// 全局页面可见性观察者。
///
/// 课程列表靠它判断「学习页已经退出、自己重新可见」，
/// 从而刷新每课的已学字数（`didPopNext`）。
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
