import 'dart:async';

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models_new/video/video_detail/data.dart';
import 'package:PiliPlus/models_new/video/video_detail/staff.dart';
import 'package:PiliPlus/models_new/video/video_tag/data.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/page.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/season.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_util.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/num_util.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class UgcIntroPanel extends StatefulWidget {
  const UgcIntroPanel({
    super.key,
    required this.heroTag,
    required this.showAiBottomSheet,
    required this.showEpisodes,
    required this.onShowMemberPage,
  });
  final String heroTag;
  final Function showAiBottomSheet;
  final Function showEpisodes;
  final ValueChanged<int?> onShowMemberPage;

  @override
  State<UgcIntroPanel> createState() => _UgcIntroPanelState();
}

class _UgcIntroPanelState extends State<UgcIntroPanel>
    with AutomaticKeepAliveClientMixin {
  late UgcIntroController ugcIntroController;
  late final VideoDetailController videoDetailCtr =
      Get.find<VideoDetailController>(tag: widget.heroTag);

  late final _coinKey = GlobalKey<ActionItemState>();
  late final _favKey = GlobalKey<ActionItemState>();

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    ugcIntroController = Get.put(UgcIntroController(), tag: widget.heroTag)
      ..heroTag = widget.heroTag;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    const expandTheme = ExpandableThemeData(
      animationDuration: Duration(milliseconds: 300),
      scrollAnimationDuration: Duration(milliseconds: 300),
      crossFadePoint: 0,
      fadeCurve: Curves.ease,
      sizeCurve: Curves.linear,
    );
    final isPortrait = context.isPortrait;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        bool isHorizontal =
            !isPortrait &&
            constraints.crossAxisExtent >
                constraints.viewportMainAxisExtent * 1.25;
        return SliverPadding(
          padding: const EdgeInsets.only(
            left: StyleString.safeSpace,
            right: StyleString.safeSpace,
            top: 10,
          ),
          sliver: Obx(
            () {
              VideoDetailData videoDetail =
                  ugcIntroController.videoDetail.value;
              bool isLoading = videoDetail.bvid == null;
              int? mid = videoDetail.owner?.mid;
              return SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (isLoading) {
                      return;
                    }
                    feedBack();
                    ugcIntroController.expandableCtr.toggle();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: Row(
                          children: [
                            if (videoDetail.staff.isNullOrEmpty) ...[
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildAvatar(
                                    theme,
                                    () {
                                      if (mid != null) {
                                        feedBack();
                                        if (!isPortrait &&
                                            ugcIntroController
                                                .horizontalMemberPage) {
                                          widget.onShowMemberPage(mid);
                                        } else {
                                          Get.toNamed(
                                            '/member?mid=$mid&from_view_aid=${videoDetailCtr.oid.value}',
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                              followButton(context, theme),
                            ] else
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: ReloadScrollPhysics(
                                    controller: ugcIntroController,
                                  ),
                                  child: Row(
                                    spacing: 25,
                                    children: videoDetail.staff!
                                        .map(
                                          (e) => _buildStaff(
                                            theme,
                                            isPortrait,
                                            mid,
                                            e,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            if (isHorizontal) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: actionGrid(
                                  context,
                                  isLoading,
                                  videoDetail,
                                  ugcIntroController,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isLoading)
                        _buildVideoTitle(theme, videoDetail)
                      else
                        ExpandablePanel(
                          controller: ugcIntroController.expandableCtr,
                          collapsed: GestureDetector(
                            onLongPress: () {
                              Feedback.forLongPress(context);
                              Utils.copyText(videoDetail.title ?? '');
                            },
                            child: _buildVideoTitle(theme, videoDetail),
                          ),
                          expanded: GestureDetector(
                            onLongPress: () {
                              Feedback.forLongPress(context);
                              Utils.copyText(videoDetail.title ?? '');
                            },
                            child: _buildVideoTitle(
                              theme,
                              videoDetail,
                              isExpand: true,
                            ),
                          ),
                          theme: expandTheme,
                        ),
                      const SizedBox(height: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildInfo(theme, videoDetail),
                          if (ugcIntroController.enableAi) _aiBtn,
                        ],
                      ),
                      if (videoDetail.argueInfo?.argueMsg?.isNotEmpty == true &&
                          ugcIntroController.showArgueMsg) ...[
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  size: 13,
                                  Icons.error_outline,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const WidgetSpan(child: SizedBox(width: 2)),
                              TextSpan(
                                text: '${videoDetail.argueInfo!.argueMsg}',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                      ExpandablePanel(
                        controller: ugcIntroController.expandableCtr,
                        collapsed: const SizedBox.shrink(),
                        expanded: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  Utils.copyText('${videoDetail.bvid}'),
                              child: Text(
                                videoDetail.bvid ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                            if (videoDetail.descV2?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              SelectableText.rich(
                                style: const TextStyle(
                                  height: 1.4,
                                ),
                                TextSpan(
                                  children: [
                                    buildContent(theme, videoDetail),
                                  ],
                                ),
                              ),
                            ],
                            Obx(() {
                              final videoTags =
                                  ugcIntroController.videoTags.value;
                              if (videoTags.isNullOrEmpty) {
                                return const SizedBox.shrink();
                              }
                              return _buildTags(videoTags!);
                            }),
                          ],
                        ),
                        theme: expandTheme,
                      ),
                      Obx(
                        () => ugcIntroController.status.value
                            ? const SizedBox.shrink()
                            : Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    ugcIntroController
                                      ..status.value = true
                                      ..queryVideoIntro();
                                    if (videoDetailCtr.videoUrl.isNullOrEmpty &&
                                        !videoDetailCtr.isQuerying) {
                                      videoDetailCtr.queryVideoUrl();
                                    }
                                  },
                                  label: const Text("点此重新加载"),
                                ),
                              ),
                      ),
                      // 点赞收藏转发 布局样式2
                      if (!isHorizontal) ...[
                        const SizedBox(height: 8),
                        actionGrid(
                          context,
                          isLoading,
                          videoDetail,
                          ugcIntroController,
                        ),
                      ],
                      // 合集
                      if (!isLoading &&
                          videoDetail.ugcSeason != null &&
                          (isPortrait ||
                              !videoDetailCtr
                                  .plPlayerController
                                  .horizontalSeasonPanel))
                        SeasonPanel(
                          heroTag: widget.heroTag,
                          onChangeEpisode: ugcIntroController.onChangeEpisode,
                          showEpisodes: widget.showEpisodes,
                          ugcIntroController: ugcIntroController,
                        ),
                      if (!isLoading &&
                          videoDetail.pages != null &&
                          videoDetail.pages!.length > 1 &&
                          (isPortrait ||
                              !videoDetailCtr
                                  .plPlayerController
                                  .horizontalSeasonPanel)) ...[
                        PagesPanel(
                          heroTag: widget.heroTag,
                          ugcIntroController: ugcIntroController,
                          bvid: ugcIntroController.bvid,
                          showEpisodes: widget.showEpisodes,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  WidgetSpan _labelWidget(String text, Color bgColor, Color textColor) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          text,
          textScaler: TextScaler.noScaling,
          strutStyle: const StrutStyle(
            leading: 0,
            height: 1,
            fontSize: 12,
          ),
          style: TextStyle(
            height: 1,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTitle(
    ThemeData theme,
    VideoDetailData videoDetail, {
    bool isExpand = false,
  }) {
    late final isDark = theme.brightness == Brightness.dark;
    Widget child() {
      final videoLabel = videoDetailCtr.videoLabel.value;
      return Text.rich(
        TextSpan(
          children: [
            if (videoLabel.isNotEmpty) ...[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 12,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ],
                      ),
                      Text(
                        videoLabel,
                        textScaler: TextScaler.noScaling,
                        strutStyle: const StrutStyle(
                          leading: 0,
                          height: 1,
                          fontSize: 13,
                        ),
                        style: TextStyle(
                          height: 1,
                          fontSize: 13,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const TextSpan(text: ' '),
            ],
            if (videoDetail.isUpowerExclusive == true) ...[
              _labelWidget(
                '充电专属',
                isDark
                    ? theme.colorScheme.error
                    : theme.colorScheme.errorContainer,
                isDark
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onErrorContainer,
              ),
              const TextSpan(text: ' '),
            ] else if (videoDetail.rights?.isSteinGate == 1) ...[
              _labelWidget(
                '互动视频',
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.onSecondaryContainer,
              ),
              const TextSpan(text: ' '),
            ],
            TextSpan(text: videoDetail.title ?? ''),
          ],
        ),
        maxLines: isExpand ? null : 2,
        overflow: isExpand ? null : TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16),
      );
    }

    if (videoDetailCtr.plPlayerController.enableSponsorBlock) {
      return Obx(child);
    }
    return child();
  }

  Future<void> handleState(FutureOr Function() action) async {
    if (!isProcessing) {
      isProcessing = true;
      await action();
      isProcessing = false;
    }
  }

  Widget followButton(BuildContext context, ThemeData t) {
    return Obx(
      () {
        int attr = ugcIntroController.followStatus['attribute'] ?? 0;
        return TextButton(
          onPressed: () => ugcIntroController.actionRelationMod(context),
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(vertical: -2.8),
            foregroundColor: attr != 0
                ? t.colorScheme.outline
                : t.colorScheme.onSecondaryContainer,
            backgroundColor: attr != 0
                ? t.colorScheme.onInverseSurface
                : t.colorScheme.secondaryContainer,
          ),
          child: Text(
            switch (attr) {
              1 => '悄悄关注',
              2 => '已关注',
              4 || 6 => '已互关',
              128 => '已拉黑',
              -10 => '特别关注',
              _ => ' 关注 ',
            },
            style: const TextStyle(fontSize: 13),
          ),
        );
      },
    );
  }

  Widget actionGrid(
    BuildContext context,
    bool isLoading,
    VideoDetailData videoDetail,
    UgcIntroController ugcIntroController,
  ) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Obx(
            () => ActionItem(
              icon: const Icon(FontAwesomeIcons.thumbsUp),
              selectIcon: const Icon(FontAwesomeIcons.solidThumbsUp),
              onTap: () => handleState(ugcIntroController.actionLikeVideo),
              onLongPress: () => handleState(ugcIntroController.actionOneThree),
              selectStatus: ugcIntroController.hasLike.value,
              semanticsLabel: '点赞',
              text: !isLoading
                  ? NumUtil.numFormat(videoDetail.stat!.like)
                  : null,
              needAnim: true,
              hasTriple:
                  ugcIntroController.hasLike.value &&
                  ugcIntroController.hasCoin &&
                  ugcIntroController.hasFav.value,
              callBack: (start) {
                if (start) {
                  HapticFeedback.lightImpact();
                  _coinKey.currentState?.controller?.forward();
                  _favKey.currentState?.controller?.forward();
                } else {
                  _coinKey.currentState?.controller?.reverse();
                  _favKey.currentState?.controller?.reverse();
                }
              },
            ),
          ),
          Obx(
            () => ActionItem(
              icon: const Icon(FontAwesomeIcons.thumbsDown),
              selectIcon: const Icon(FontAwesomeIcons.solidThumbsDown),
              onTap: () => handleState(ugcIntroController.actionDislikeVideo),
              selectStatus: ugcIntroController.hasDislike.value,
              semanticsLabel: '点踩',
              text: "点踩",
            ),
          ),
          Obx(
            () => ActionItem(
              key: _coinKey,
              icon: const Icon(FontAwesomeIcons.b),
              selectIcon: const Icon(FontAwesomeIcons.b),
              onTap: () => handleState(ugcIntroController.actionCoinVideo),
              selectStatus: ugcIntroController.hasCoin,
              semanticsLabel: '投币',
              text: !isLoading
                  ? NumUtil.numFormat(videoDetail.stat!.coin)
                  : null,
              needAnim: true,
            ),
          ),
          Obx(
            () => ActionItem(
              key: _favKey,
              icon: const Icon(FontAwesomeIcons.star),
              selectIcon: const Icon(FontAwesomeIcons.solidStar),
              onTap: () => ugcIntroController.showFavBottomSheet(context),
              onLongPress: () => ugcIntroController.showFavBottomSheet(
                context,
                isLongPress: true,
              ),
              selectStatus: ugcIntroController.hasFav.value,
              semanticsLabel: '收藏',
              text: !isLoading
                  ? NumUtil.numFormat(videoDetail.stat!.favorite)
                  : null,
              needAnim: true,
            ),
          ),
          Obx(
            () => ActionItem(
              icon: const Icon(FontAwesomeIcons.clock),
              selectIcon: const Icon(FontAwesomeIcons.solidClock),
              onTap: () => handleState(ugcIntroController.viewLater),
              selectStatus: ugcIntroController.hasLater.value,
              semanticsLabel: '再看',
              text: '再看',
            ),
          ),
          ActionItem(
            icon: const Icon(FontAwesomeIcons.shareFromSquare),
            onTap: () => ugcIntroController.actionShareVideo(context),
            selectStatus: false,
            semanticsLabel: '分享',
            text: !isLoading
                ? NumUtil.numFormat(videoDetail.stat!.share!)
                : null,
          ),
        ],
      ),
    );
  }

  static final RegExp urlRegExp = RegExp(
    '${Constants.urlRegex.pattern}|av\\d+|bv[a-z\\d]{10}',
    caseSensitive: false,
  );

  InlineSpan buildContent(ThemeData theme, VideoDetailData content) {
    if (content.descV2.isNullOrEmpty) {
      return const TextSpan();
    }
    // type
    // 1 普通文本
    // 2 @用户
    final List<TextSpan> spanChildren = content.descV2!.map((currentDesc) {
      switch (currentDesc.type) {
        case 1:
          final List<InlineSpan> spanChildren = <InlineSpan>[];
          (currentDesc.rawText as String).splitMapJoin(
            urlRegExp,
            onMatch: (Match match) {
              String matchStr = match[0]!;
              if (matchStr.toLowerCase().startsWith('http')) {
                spanChildren.add(
                  TextSpan(
                    text: matchStr,
                    style: TextStyle(color: theme.colorScheme.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        try {
                          PageUtils.handleWebview(matchStr);
                        } catch (err) {
                          SmartDialog.showToast(err.toString());
                        }
                      },
                  ),
                );
              } else if (matchStr.startsWith('av')) {
                try {
                  int aid = int.parse(matchStr.substring(2));
                  IdUtils.av2bv(aid);
                  spanChildren.add(
                    TextSpan(
                      text: matchStr,
                      style: TextStyle(color: theme.colorScheme.primary),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => PiliScheme.videoPush(aid, null),
                    ),
                  );
                } catch (e) {
                  spanChildren.add(TextSpan(text: matchStr));
                }
              } else {
                try {
                  IdUtils.bv2av(matchStr);
                  spanChildren.add(
                    TextSpan(
                      text: matchStr,
                      style: TextStyle(color: theme.colorScheme.primary),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => PiliScheme.videoPush(null, matchStr),
                    ),
                  );
                } catch (e) {
                  spanChildren.add(TextSpan(text: matchStr));
                }
              }
              return '';
            },
            onNonMatch: (String nonMatchStr) {
              spanChildren.add(TextSpan(text: nonMatchStr));
              return '';
            },
          );
          return TextSpan(children: spanChildren);
        case 2:
          final Color colorSchemePrimary = theme.colorScheme.primary;
          return TextSpan(
            text: '@${currentDesc.rawText}',
            style: TextStyle(color: colorSchemePrimary),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed('/member?mid=${currentDesc.bizId}'),
          );
        default:
          return const TextSpan();
      }
    }).toList();
    return TextSpan(children: spanChildren);
  }

  Widget _buildStaff(
    ThemeData theme,
    bool isPortrait,
    int? ownerMid,
    Staff item,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.mid == ownerMid &&
            !isPortrait &&
            ugcIntroController.horizontalMemberPage) {
          widget.onShowMemberPage(ownerMid);
        } else {
          Get.toNamed(
            '/member?mid=${item.mid}&from_view_aid=${videoDetailCtr.oid.value}',
          );
        }
      },
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              NetworkImgLayer(
                type: ImageType.avatar,
                src: item.face,
                width: 35,
                height: 35,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
              ),
              if ((item.official?.type ?? -1) != -1)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child: Icon(
                      Icons.offline_bolt,
                      color: item.official?.type == 0
                          ? const Color(0xFFFFCC00)
                          : Colors.lightBlueAccent,
                      size: 14,
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: -6,
                child: Obx(
                  () =>
                      ugcIntroController.staffRelations['status'] == true &&
                          ugcIntroController.staffRelations['${item.mid}'] ==
                              null
                      ? Material(
                          type: MaterialType.transparency,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => RequestUtils.actionRelationMod(
                              context: context,
                              mid: item.mid,
                              isFollow: false,
                              callback: (val) {
                                ugcIntroController
                                        .staffRelations['${item.mid}'] =
                                    true;
                              },
                            ),
                            child: Ink(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                MdiIcons.plus,
                                size: 16,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: (item.vip?.status ?? 0) > 0 && item.vip?.type == 2
                      ? context.vipColor
                      : null,
                ),
              ),
              Text(
                item.title!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    ThemeData theme,
    VoidCallback onPushMember,
  ) => GestureDetector(
    onTap: onPushMember,
    behavior: HitTestBehavior.opaque,
    child: Obx(
      () {
        final userStat = ugcIntroController.userStat.value;
        final isVip = (userStat.card?.vip?.status ?? 0) > 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PendantAvatar(
              avatar: userStat.card?.face,
              size: 35,
              badgeSize: 14,
              isVip: isVip,
              officialType: userStat.card?.officialVerify?.type,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userStat.card?.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isVip && userStat.card?.vip?.type == 2
                        ? context.vipColor
                        : null,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  '${NumUtil.numFormat(userStat.follower)}粉丝    ${'${NumUtil.numFormat(userStat.archiveCount)}视频'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Widget _buildInfo(ThemeData theme, VideoDetailData videoDetail) => Row(
    spacing: 10,
    children: [
      StatWidget(
        type: StatType.play,
        value: videoDetail.stat?.view,
        color: theme.colorScheme.outline,
      ),
      StatWidget(
        type: StatType.danmaku,
        value: videoDetail.stat?.danmaku,
        color: theme.colorScheme.outline,
      ),
      Text(
        DateUtil.format(videoDetail.pubdate),
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.outline,
        ),
      ),
      if (MineController.anonymity.value)
        Icon(
          MdiIcons.incognito,
          size: 15,
          color: theme.colorScheme.outline,
          semanticLabel: '无痕',
        ),
      if (ugcIntroController.isShowOnlineTotal)
        Obx(
          () => Text(
            '${ugcIntroController.total.value}人在看',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
        ),
    ],
  );

  Widget get _aiBtn => Positioned(
    right: 10,
    top: 0,
    bottom: 0,
    child: Center(
      child: Semantics(
        label: 'AI总结',
        child: GestureDetector(
          onTap: () async {
            if (ugcIntroController.aiConclusionResult == null) {
              await ugcIntroController.aiConclusion();
            }
            if (ugcIntroController.aiConclusionResult == null) {
              return;
            }
            if (ugcIntroController.aiConclusionResult!.summary?.isNotEmpty ==
                    true ||
                ugcIntroController.aiConclusionResult!.outline?.isNotEmpty ==
                    true) {
              widget.showAiBottomSheet();
            } else {
              SmartDialog.showToast("当前视频不支持AI视频总结");
            }
          },
          child: Image.asset('assets/images/ai.png', height: 22),
        ),
      ),
    ),
  );

  Widget _buildTags(List<VideoTagItem> tags) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (item) => SearchText(
                  fontSize: 13,
                  text: item.tagName!,
                  onTap: (tagName) => Get.toNamed(
                    '/searchResult',
                    parameters: {'keyword': tagName},
                  ),
                  onLongPress: Utils.copyText,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
