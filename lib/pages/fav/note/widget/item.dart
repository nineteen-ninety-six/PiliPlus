import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/fav/fav_note/list.dart';
import 'package:PiliPlus/pages/fav/note/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';

class FavNoteItem extends StatelessWidget {
  const FavNoteItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onSelect,
  });

  final FavNoteItemModel item;
  final FavNoteController ctr;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          if (ctr.enableMultiSelect.value) {
            onSelect();
            return;
          }
          if (item.webUrl?.isNotEmpty == true) {
            PageUtils.handleWebview(
              item.webUrl!,
              inApp: true,
            );
          }
        },
        onLongPress: () {
          if (!ctr.enableMultiSelect.value) {
            ctr.enableMultiSelect.value = true;
            onSelect();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleString.safeSpace,
            vertical: 5,
          ),
          child: Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.pic?.isNotEmpty == true)
                AspectRatio(
                  aspectRatio: StyleString.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          NetworkImgLayer(
                            src: item.pic,
                            width: boxConstraints.maxWidth,
                            height: boxConstraints.maxHeight,
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: LayoutBuilder(
                                builder: (context, constraints) =>
                                    AnimatedOpacity(
                                      opacity: item.checked == true ? 1 : 0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: constraints.maxHeight,
                                        width:
                                            constraints.maxHeight *
                                            StyleString.aspectRatio,
                                        decoration: BoxDecoration(
                                          borderRadius: StyleString.mdRadius,
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                        child: SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: AnimatedScale(
                                            scale: item.checked == true ? 1 : 0,
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeInOut,
                                            child: IconButton(
                                              tooltip: '取消选择',
                                              style: ButtonStyle(
                                                padding:
                                                    WidgetStateProperty.all(
                                                      EdgeInsets.zero,
                                                    ),
                                                backgroundColor:
                                                    WidgetStatePropertyAll(
                                                      theme.colorScheme.surface
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                              ),
                                              onPressed: null,
                                              icon: Icon(
                                                Icons.done_all_outlined,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.summary ?? '',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.message ?? '',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
